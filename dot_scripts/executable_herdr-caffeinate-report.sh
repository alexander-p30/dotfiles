#!/usr/bin/env bash
# herdr-caffeinate-report.sh — show caffeinate keep-awake state per herdr space.
#
# caffeinate is a global (system-wide) process, but each one is attributed to a
# space by its working directory: the token is pushed only to the workspace
# whose directory contains the caffeinate's cwd (longest-path match), and
# cleared on every other workspace. A caffeinate whose cwd is under no space is
# not shown. Run every ~15s by the launchd agent
# com.estevanalexander.moka-herdr-indicator. Idempotent; a no-op when herdr is down.
set -uo pipefail

HERDR="${HERDR_BIN:-$HOME/.local/bin/herdr}"
[[ -x "$HERDR" ]] || HERDR="herdr"
MOKA="${MOKA_BIN:-$HOME/.scripts/moka.sh}"
TTL_MS="${MOKA_HERDR_TTL_MS:-15000}"

command -v "$HERDR" >/dev/null 2>&1 || exit 0

snapshot="$("$HERDR" api snapshot 2>/dev/null)" || exit 0
[[ -n "$snapshot" ]] || exit 0

# Per-process caffeinate lines: "<cwd>\t<token>".
list="$("$MOKA" status --format list 2>/dev/null)" || list=""

# Resolve, for every workspace, the token it should show ("" = clear). Matching:
# the workspace whose pane cwd is the longest prefix of a caffeinate's cwd wins;
# a managed ☕ token beats an unmanaged ☕⚠ when several land on one space.
plan="$(printf '%s' "$snapshot" | MOKA_LIST="$list" python3 -c '
import sys, json, os

try:
    snap = json.load(sys.stdin)["result"]["snapshot"]
except Exception:
    sys.exit(0)

ws_ids = [w["workspace_id"] for w in snap.get("workspaces", [])]
ws_cwds = {}
for coll in ("panes", "agents"):
    for p in snap.get(coll, []):
        wid = p.get("workspace_id")
        cw = p.get("cwd") or p.get("foreground_cwd")
        if wid and cw:
            ws_cwds.setdefault(wid, []).append(cw.rstrip("/"))

def under(base, path):  # path == base or path is inside base
    return path == base or path.startswith(base + "/")

ws_token = {}
for line in os.environ.get("MOKA_LIST", "").splitlines():
    if "\t" not in line:
        continue
    cwd, token = line.split("\t", 1)
    cwd = cwd.rstrip("/")
    if not cwd or cwd == "?" or not token:
        continue
    best_wid, best_len = None, -1
    for wid, cwds in ws_cwds.items():
        for base in cwds:
            if under(base, cwd) and len(base) > best_len:
                best_len, best_wid = len(base), wid
    if best_wid is None:
        continue  # not under any space -> not shown
    cur = ws_token.get(best_wid)
    if cur is None or ("⚠" in cur and "⚠" not in token):
        ws_token[best_wid] = token

for wid in ws_ids:
    print(wid + "\t" + ws_token.get(wid, ""))
')" || exit 0

[[ -n "$plan" ]] || exit 0

while IFS=$'\t' read -r wid tok; do
  [[ -n "$wid" ]] || continue
  if [[ -n "$tok" ]]; then
    "$HERDR" workspace report-metadata "$wid" --source moka \
      --token "caffeinate=$tok" --ttl-ms "$TTL_MS" >/dev/null 2>&1 || true
  else
    "$HERDR" workspace report-metadata "$wid" --source moka \
      --clear-token caffeinate >/dev/null 2>&1 || true
  fi
done <<<"$plan"
