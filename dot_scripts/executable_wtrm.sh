#!/usr/bin/env bash
# wtrm — a live TUI for pruning old git worktrees across every repo `gt` knows.
#
# Same universe as gt (all main repos under employ_workspace, plus the repo you're
# standing in): it lists every *linked* worktree — never the main worktrees, which
# can't be removed — and lets you multi-select and batch `git worktree remove` them.
#
# Per row: a green ● if a herdr session is open there (like gt), a ✱ if the worktree
# is dirty, a ⚠ if it's stale (its working dir is gone), and the timestamp + "Nd ago"
# of its newest file ("last activity"). The list reloads on every delete and when you
# press r (never on a timer). The slow dirty/timestamp scan runs in the BACKGROUND so
# the UI never hangs — a reverse-video ⟳ banner shows its progress and during deletes.
#
# `git worktree remove` runs WITHOUT --force on purpose. A dirty (✱) worktree fails and
# its error is shown verbatim — press `o` to open it in a vertical herdr split and
# finish the --force by hand. A stale (⚠) worktree can't be opened or removed at all, so
# delete falls back to `git worktree prune` for it (safe: the working copy is gone).
#
# Keys: ↑↓/j k move · space/tab select · d/⏎ delete · o open in split · r refresh
#       · q/esc quit.  macOS-only (BSD `stat`, herdr).
#
# Sourceable for tests: the bottom guard only runs wtr_main when executed directly.
set -uo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
WTR_MAXMSG=6         # status/error lines shown above the help footer
# Build/dep dirs pruned from the activity scan: they hold no "did I work here" signal
# and get churned by builds, which would make every row read as "just now".
WTR_PRUNE_DIRS=(.git node_modules _build deps .elixir_ls target tmp .next dist cover .terraform vendor)

# ---------------------------------------------------------------------------
# State (global so it survives the loop; dirty/activity are keyed by path and
# recomputed in full on each refresh)
# ---------------------------------------------------------------------------
declare -a WTR_PATHS=()      # ordered worktree paths == the visible rows
declare -A WTR_REPO=()       # path -> owning main repo dir (where `git -C` runs)
declare -A WTR_BRANCH=()     # path -> branch label (or "(detached)")
declare -A WTR_PRUNABLE=()   # path -> 1 if git marked it prunable/stale
declare -A WTR_SESSION=()    # path -> 1 if a herdr agent's cwd is in it
declare -A WTR_DIRTY=()      # path -> 1 dirty, 0 clean, -1 gone
declare -A WTR_ACT=()        # path -> epoch of newest file mtime (unset = not yet scanned, 0 = gone)
declare -A WTR_SELECTED=()   # path -> 1 if marked for deletion
declare -a WTR_MSGS=()       # status log (pre-colored); last WTR_MAXMSG rendered
WTR_CURSOR=0                 # index into WTR_PATHS
WTR_TOP=0                    # first visible row index (viewport scroll)
WTR_BUSY=""                  # non-empty -> reverse-video banner text (delete in progress)
WTR_SCANFILE=""              # temp file the background scanner streams results into
WTR_SCAN_PID=""              # pid of the running background scan (empty when none)
WTR_SCAN_TOTAL=0             # rows the current scan will cover
WTR_SCAN_DONE=0              # rows the scan has finished so far (from wtr_drain_scan)
WTR_QUIT=0
WTR_ROWS=24 WTR_COLS=80

# ---------------------------------------------------------------------------
# Small pure helpers (unit-tested)
# ---------------------------------------------------------------------------
# wtr_now — current epoch, overridable via $WTR_NOW so time-based logic is testable.
wtr_now() { printf '%s' "${WTR_NOW:-$(date +%s)}"; }

# wtr_fmt_ts <epoch> — last-activity timestamp "YYYY-MM-DD HH:MM" (or — if unknown).
wtr_fmt_ts() {
  local e="${1:-}"
  if [[ -z "$e" || "$e" == 0 ]]; then printf -- '—'; return; fi
  date -r "$e" '+%Y-%m-%d %H:%M' 2>/dev/null || printf -- '—'
}

# wtr_ago <epoch> — how long since <epoch>, shown beside the timestamp: "just now"
# / "5m ago" / "3h ago" / "21d ago" / "4mo ago" (empty for unknown). $WTR_NOW-testable.
wtr_ago() {
  local e="${1:-}" now d
  if [[ -z "$e" || "$e" == 0 ]]; then printf ''; return; fi
  now=$(wtr_now); d=$(( now - e )); (( d < 0 )) && d=0
  if   (( d < 60 ));      then printf 'just now'
  elif (( d < 3600 ));    then printf '%dm ago'  $(( d / 60 ))
  elif (( d < 86400 ));   then printf '%dh ago'  $(( d / 3600 ))
  elif (( d < 2592000 )); then printf '%dd ago'  $(( d / 86400 ))
  else                        printf '%dmo ago' $(( d / 2592000 )); fi
}

# wtr_parse_worktrees <repo> — read `git worktree list --porcelain` on stdin and
# emit "<repo>\t<path>\t<branch>\t<prunable>" for every worktree EXCEPT the first
# (the main worktree, which is never removable). Pure; unit-tested.
wtr_parse_worktrees() {
  awk -v repo="$1" '
    function flush(   ) {
      if (path != "") { n++; if (n > 1) print repo "\t" path "\t" branch "\t" prun }
      path = ""; branch = "(detached)"; prun = 0
    }
    BEGIN { n = 0; path = ""; branch = "(detached)"; prun = 0 }
    /^worktree /  { flush(); path = substr($0, 10) }
    /^branch /    { r = substr($0, 8); sub(/^refs\/heads\//, "", r); branch = r }
    /^detached/   { branch = "(detached)" }
    /^prunable /  { prun = 1 }
    END { flush() }
  '
}

# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------
# wtr_main_repos — the main repos to scan: employ_workspace + its git subdirs,
# plus the main worktree of wherever you invoked wtrm (so it works from any repo).
wtr_main_repos() {
  local ws="${WTR_WS:-$HOME/Projects/remote/employ_workspace}"
  {
    [[ -d "$ws/.git" ]] && printf '%s\n' "$ws"
    local d
    for d in "$ws"/*/; do [[ -d "$d/.git" ]] && printf '%s\n' "${d%/}"; done
    local gcd main
    gcd=$(git -C "$PWD" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if [[ -n "$gcd" ]]; then main="${gcd%/.git}"; [[ "$main" != "$gcd" ]] && printf '%s\n' "$main"; fi
  } | awk 'NF && !seen[$0]++'
}

# wtr_refresh_sessions — mark worktrees that have an open herdr agent (cwd inside).
wtr_refresh_sessions() {
  WTR_SESSION=()
  local cwds p c
  cwds=$(herdr agent list 2>/dev/null \
           | jq -r '.result.agents[]? | (.cwd, .foreground_cwd) | select(. != null)' 2>/dev/null)
  [[ -z "$cwds" ]] && return
  for p in "${WTR_PATHS[@]}"; do
    while IFS= read -r c; do
      [[ -z "$c" ]] && continue
      if [[ "$c" == "$p" || "$c" == "$p/"* ]]; then WTR_SESSION["$p"]=1; break; fi
    done <<< "$cwds"
  done
}

# wtr_discover — rebuild the row list (cheap: git worktree list per repo + herdr),
# preserving cursor (by path) and selections. Dirty/activity are filled in by the
# caller (wtr_refresh); discover alone leaves them as-is.
wtr_discover() {
  local cur="${WTR_PATHS[$WTR_CURSOR]:-}"
  WTR_PATHS=(); WTR_REPO=(); WTR_BRANCH=(); WTR_PRUNABLE=()
  local repos rows r repo path branch prun
  repos=$(wtr_main_repos)
  rows=$(
    while IFS= read -r r; do
      [[ -z "$r" ]] && continue
      git -C "$r" worktree list --porcelain 2>/dev/null | wtr_parse_worktrees "$r"
    done <<< "$repos" | sort -t $'\t' -k1,1 -k3,3
  )
  while IFS=$'\t' read -r repo path branch prun; do
    [[ -z "$path" ]] && continue
    WTR_PATHS+=( "$path" )
    WTR_REPO["$path"]="$repo"
    WTR_BRANCH["$path"]="$branch"
    WTR_PRUNABLE["$path"]="$prun"
  done <<< "$rows"
  wtr_refresh_sessions
  wtr_prune_selected
  wtr_cursor_to "$cur"
}

wtr_prune_selected() {
  local p; local -A present=()
  for p in "${WTR_PATHS[@]}"; do present["$p"]=1; done
  for p in "${!WTR_SELECTED[@]}"; do [[ -n "${present[$p]:-}" ]] || unset 'WTR_SELECTED[$p]'; done
}

# ---------------------------------------------------------------------------
# Heavy per-row state: dirty flag + newest-file mtime (~0.3s/worktree). This is the
# slow part, so it runs in a BACKGROUND process that streams "path\tdirty\tmtime"
# lines into a temp file; the main loop drains them between keypresses. The UI never
# blocks on the scan — rows fill in their dirty (✱) / timestamp as results arrive.
# ---------------------------------------------------------------------------
# wtr_scan_one <path> — print "dirty\tmtime" (dirty: 1/0/-1-gone; mtime epoch, 0=none).
wtr_scan_one() {
  local p="$1" dirty find_prune=() d mt
  if [[ ! -d "$p" ]]; then printf -- '-1\t0'; return; fi
  [[ -n "$(git -C "$p" status --porcelain 2>/dev/null | head -1)" ]] && dirty=1 || dirty=0
  for d in "${WTR_PRUNE_DIRS[@]}"; do find_prune+=( -name "$d" -o ); done
  unset 'find_prune[-1]'
  mt=$(find "$p" -type d \( "${find_prune[@]}" \) -prune -o -type f -print0 2>/dev/null \
         | xargs -0 stat -f '%m' 2>/dev/null | sort -rn | head -1)
  printf -- '%s\t%s' "$dirty" "${mt:-0}"
}

# wtr_start_scan — (re)launch the background scan for the current row set.
wtr_start_scan() {
  wtr_stop_scan
  : > "$WTR_SCANFILE"
  WTR_SCAN_TOTAL=${#WTR_PATHS[@]}
  local paths=( "${WTR_PATHS[@]}" )
  {
    local p res
    for p in "${paths[@]}"; do
      res=$(wtr_scan_one "$p")
      printf '%s\t%s\n' "$p" "$res" >> "$WTR_SCANFILE"   # one atomic append per row
    done
  } &
  WTR_SCAN_PID=$!
}

wtr_stop_scan() {
  if [[ -n "${WTR_SCAN_PID:-}" ]] && kill -0 "$WTR_SCAN_PID" 2>/dev/null; then
    pkill -P "$WTR_SCAN_PID" 2>/dev/null   # kill the in-flight git/find child too
    kill "$WTR_SCAN_PID" 2>/dev/null
  fi
  WTR_SCAN_PID=""
}

wtr_scanning() { [[ -n "${WTR_SCAN_PID:-}" ]] && kill -0 "$WTR_SCAN_PID" 2>/dev/null; }

# wtr_drain_scan — fold whatever the scanner has written so far into the caches.
# Idempotent (re-reads the whole small file); sets WTR_SCAN_DONE to rows completed.
wtr_drain_scan() {
  WTR_SCAN_DONE=0
  [[ -s "$WTR_SCANFILE" ]] || return
  local p dirty mt
  while IFS=$'\t' read -r p dirty mt; do
    [[ -z "$p" || -z "$mt" ]] && continue
    WTR_DIRTY["$p"]=$dirty; WTR_ACT["$p"]=$mt
    WTR_SCAN_DONE=$(( WTR_SCAN_DONE + 1 ))
  done < "$WTR_SCANFILE"
}

# ---------------------------------------------------------------------------
# Cursor / selection helpers
# ---------------------------------------------------------------------------
wtr_clamp_cursor() {
  local n=${#WTR_PATHS[@]}
  (( n == 0 )) && { WTR_CURSOR=0; return; }
  (( WTR_CURSOR < 0 ))   && WTR_CURSOR=0
  (( WTR_CURSOR >= n ))  && WTR_CURSOR=$(( n - 1 ))
}

wtr_cursor_to() {  # move cursor onto <path> if it still exists, else clamp
  local target="$1" i
  if [[ -n "$target" ]]; then
    for i in "${!WTR_PATHS[@]}"; do
      [[ "${WTR_PATHS[$i]}" == "$target" ]] && { WTR_CURSOR=$i; wtr_clamp_cursor; return; }
    done
  fi
  wtr_clamp_cursor
}

wtr_msg() { WTR_MSGS+=( "$1" ); (( ${#WTR_MSGS[@]} > 40 )) && WTR_MSGS=( "${WTR_MSGS[@]: -40}" ); }

# ---------------------------------------------------------------------------
# Colors & terminal size
# ---------------------------------------------------------------------------
wtr_setup_colors() {
  if [[ -n "${NO_COLOR:-}" ]] || { [[ ! -t 1 ]] && [[ -z "${WTR_FORCE_COLOR:-}" ]]; }; then
    RST= DIM= BLD= RED= GRN= YEL= ACC= REV= ; return
  fi
  RST=$'\033[0m'; DIM=$'\033[2m'; BLD=$'\033[1m'
  RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; ACC=$'\033[36m'
  REV=$'\033[7m'   # reverse video — the busy banner, so a refresh/delete can't be missed
}

wtr_size() {
  local sz
  sz=$(stty size </dev/tty 2>/dev/null) || sz=$(stty size 2>/dev/null) || sz="24 80"
  WTR_ROWS=${sz%% *}; WTR_COLS=${sz##* }
  [[ "$WTR_ROWS" =~ ^[0-9]+$ ]] || WTR_ROWS=24
  [[ "$WTR_COLS" =~ ^[0-9]+$ ]] || WTR_COLS=80
}

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------
# wtr_rowstr <index> -> sets $row to the fully-colored, width-fitted line.
wtr_rowstr() {
  local i="$1" p rname br dv dmark tsstr agostr
  p="${WTR_PATHS[$i]}"
  rname="${WTR_REPO[$p]##*/}"
  br="${WTR_BRANCH[$p]}"
  if [[ -z "${WTR_ACT[$p]+set}" ]]; then
    dmark=' '; tsstr='·'; agostr=''             # not scanned yet
  else
    dv="${WTR_DIRTY[$p]:-0}"
    case "$dv" in 1) dmark='✱';; -1) dmark='⚠';; *) dmark=' ';; esac
    tsstr=$(wtr_fmt_ts "${WTR_ACT[$p]:-0}"); agostr=$(wtr_ago "${WTR_ACT[$p]:-0}")
  fi
  [[ "${WTR_PRUNABLE[$p]:-0}" == 1 && "$dmark" == ' ' ]] && dmark='⚠'

  # truncate the branch (repo name is short and always kept) to fit the width
  local avail=$(( WTR_COLS - 37 )); (( avail < 12 )) && avail=12
  local labelplain="$rname · $br" keep
  if (( ${#labelplain} > avail )); then
    keep=$(( avail - ${#rname} - 4 )); (( keep < 1 )) && keep=1
    br="${br:0:keep}…"; labelplain="$rname · $br"
  fi

  local iscur=0; (( i == WTR_CURSOR )) && iscur=1
  local curcol='  '; (( iscur )) && curcol="${ACC}▸ ${RST}"
  local selcol; [[ -n "${WTR_SELECTED[$p]:-}" ]] && selcol="${GRN}[x]${RST}" || selcol="${DIM}[ ]${RST}"
  local sesscol=' '; [[ "${WTR_SESSION[$p]:-0}" == 1 ]] && sesscol="${GRN}●${RST}"
  local labcol
  if (( iscur )); then labcol="${DIM}${rname} · ${RST}${BLD}${br}${RST}"
  else                 labcol="${DIM}${rname} · ${RST}${br}"; fi
  local dcol=' '
  case "$dmark" in '✱') dcol="${YEL}✱${RST}";; '⚠') dcol="${RED}⚠${RST}";; esac

  local pad=$(( WTR_COLS - 8 - ${#labelplain} - 28 )); (( pad < 1 )) && pad=1
  printf -v row '%s%s %s %s%*s%s %16s %s%-8s%s' \
    "$curcol" "$selcol" "$sesscol" "$labcol" "$pad" "" "$dcol" "$tsstr" "$DIM" "$agostr" "$RST"
}

wtr_draw() {
  wtr_size
  local -a L=()
  local n=${#WTR_PATHS[@]} row

  printf -v row '%s wtrm%s  %s%d worktrees · %d selected%s' \
    "$BLD" "$RST" "$DIM" "$n" "${#WTR_SELECTED[@]}" "$RST"
  L+=( "$row" )
  # Prominent reverse-video banner while work is happening: a delete in progress
  # (WTR_BUSY, blocking) or the non-blocking background scan filling in timestamps.
  # Idle it's just a blank separator line.
  local banner=""
  if [[ -n "$WTR_BUSY" ]]; then banner="$WTR_BUSY"
  elif wtr_scanning;      then banner="scanning ${WTR_SCAN_DONE}/${WTR_SCAN_TOTAL} (timestamps)…"
  fi
  if [[ -n "$banner" ]]; then
    local bt="  ⟳ ${banner}"; local bw=$(( WTR_COLS - ${#bt} )); (( bw < 1 )) && bw=1
    printf -v row '%s%s%s%*s%s' "$REV" "$BLD" "$bt" "$bw" "" "$RST"
    L+=( "$row" )
  else
    L+=( "" )
  fi

  local nmsg=${#WTR_MSGS[@]}; (( nmsg > WTR_MAXMSG )) && nmsg=$WTR_MAXMSG
  local msgblock=$(( nmsg > 0 ? nmsg + 1 : 0 ))
  local listh=$(( WTR_ROWS - 2 - 1 - msgblock )); (( listh < 1 )) && listh=1

  # keep cursor within the viewport
  (( WTR_CURSOR < WTR_TOP ))            && WTR_TOP=$WTR_CURSOR
  (( WTR_CURSOR >= WTR_TOP + listh ))   && WTR_TOP=$(( WTR_CURSOR - listh + 1 ))
  (( WTR_TOP < 0 ))                     && WTR_TOP=0

  if (( n == 0 )); then
    L+=( "  ${DIM}No linked worktrees found.${RST}" )
    local pad; for (( pad = 1; pad < listh; pad++ )); do L+=( "" ); done
  else
    local i end=$(( WTR_TOP + listh )); (( end > n )) && end=$n
    for (( i = WTR_TOP; i < end; i++ )); do wtr_rowstr "$i"; L+=( "$row" ); done
    local shown=$(( end - WTR_TOP )) pad
    for (( pad = shown; pad < listh; pad++ )); do L+=( "" ); done
  fi

  if (( nmsg > 0 )); then
    L+=( "" )
    local m start=$(( ${#WTR_MSGS[@]} - nmsg ))
    for (( m = start; m < ${#WTR_MSGS[@]}; m++ )); do L+=( "${WTR_MSGS[$m]}" ); done
  fi

  printf -v row '%s↑↓/jk move · space select · d delete · o open split · r refresh · q quit%s' "$DIM" "$RST"
  L+=( "$row" )

  local buf=$'\033[H' ln
  for ln in "${L[@]}"; do buf+="${ln}"$'\033[K\n'; done
  buf+=$'\033[J'
  printf '%s' "$buf"
}

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------
wtr_label() { printf '%s · %s' "${WTR_REPO[$1]##*/}" "${WTR_BRANCH[$1]}"; }

# wtr_short_err <git-stderr> — collapse git's verbose failure into a short reason
# (the row label already names the worktree, so the path/"fatal:" are just noise).
wtr_short_err() {
  local m; m=$(printf '%s' "$1" | head -1)
  case "$m" in
    *"contains modified or untracked files"*) printf 'dirty — press o to --force'; return ;;
    *"is locked"*|*"locked working tree"*)    printf 'locked — press o to --force'; return ;;
    *"is a main working tree"*)               printf 'main worktree (cannot remove)'; return ;;
    *"is not a working tree"*)                printf 'not a working tree';           return ;;
  esac
  m=${m#fatal: }
  printf '%s' "$m" | sed -E "s|'/[^']*'|it|g"   # drop the long absolute path
}

# wtr_reload — re-list worktrees (fast) and kick off the background scan. Returns
# immediately; the UI stays responsive while dirty/timestamps stream in.
wtr_reload() {
  wtr_discover
  wtr_start_scan
}

# wtr_confirm <n> — inline y/N prompt on the status line; returns 0 if confirmed.
wtr_confirm() {
  wtr_msg "${YEL}Delete ${1} worktree(s)? [y/N]${RST}"
  wtr_draw
  local a=""; IFS= read -rsn1 a
  unset 'WTR_MSGS[-1]'
  [[ "$a" == y || "$a" == Y ]]
}

wtr_do_delete() {
  local -a targets=()
  local p
  if (( ${#WTR_SELECTED[@]} )); then
    for p in "${WTR_PATHS[@]}"; do [[ -n "${WTR_SELECTED[$p]:-}" ]] && targets+=( "$p" ); done
  else
    p="${WTR_PATHS[$WTR_CURSOR]:-}"; [[ -n "$p" ]] && targets+=( "$p" )
  fi
  (( ${#targets[@]} )) || { wtr_msg "${DIM}nothing to delete${RST}"; return; }
  wtr_confirm "${#targets[@]}" || { wtr_msg "${DIM}cancelled${RST}"; return; }

  # Delete one at a time, redrawing before and after each so progress is visible
  # (a large batch used to freeze the UI until the whole thing finished).
  local repo out rc label n=${#targets[@]} i=0
  for p in "${targets[@]}"; do
    i=$(( i + 1 )); repo="${WTR_REPO[$p]}"; label="$(wtr_label "$p")"
    WTR_BUSY="deleting ${i}/${n}: ${label}"; wtr_draw
    out=$(git -C "$repo" worktree remove "$p" 2>&1); rc=$?
    if (( rc == 0 )); then
      wtr_msg "${GRN}✓ removed ${label}${RST}"; unset 'WTR_SELECTED[$p]'
    elif [[ ! -e "$p/.git" ]]; then
      # Stale worktree: its working copy (and .git) are gone, so `remove` — even
      # with --force — refuses ("'…/.git' does not exist"). There is nothing to
      # lose, so clean the dangling admin entry with `git worktree prune`.
      WTR_BUSY="pruning ${i}/${n}: ${label}"; wtr_draw
      git -C "$repo" worktree prune >/dev/null 2>&1
      if git -C "$repo" worktree list --porcelain 2>/dev/null | grep -qxF -- "worktree $p"; then
        wtr_msg "${RED}✗ ${label}${RST} ${DIM}$(wtr_short_err "$out")${RST}"
      else
        wtr_msg "${GRN}✓ removed ${label} ${DIM}(stale)${RST}"; unset 'WTR_SELECTED[$p]'
      fi
    else
      # Dir present but remove failed. "dirty"/"locked" is expected (you finish the
      # --force by hand after `o`), so show it as a soft ⊘ note, not a red error.
      local reason; reason=$(wtr_short_err "$out")
      case "$reason" in
        dirty*|locked*) wtr_msg "${YEL}⊘ ${label}${RST} ${DIM}${reason}${RST}" ;;
        *)              wtr_msg "${RED}✗ ${label}${RST} ${DIM}${reason}${RST}" ;;
      esac
    fi
    wtr_draw   # surface this row's result immediately
  done
  WTR_BUSY=""
  wtr_reload   # re-list + kick off a fresh background scan (non-blocking)
}

# wtr_do_open — open the cursor's worktree in a vertical herdr split (right of the
# focused pane) so the manual `git worktree remove --force` can be done there.
wtr_do_open() {
  local p="${WTR_PATHS[$WTR_CURSOR]:-}"
  [[ -n "$p" ]] || return
  local label; label="$(wtr_label "$p")"
  if [[ ! -d "$p" ]]; then wtr_msg "${YEL}${label}: directory is gone — nothing to open${RST}"; return; fi
  local fp np
  fp=$(herdr api snapshot 2>/dev/null | jq -r '.result.snapshot.focused_pane_id // empty')
  [[ -n "$fp" ]] || { wtr_msg "${RED}couldn't find the focused herdr pane${RST}"; return; }
  np=$(herdr pane split --pane "$fp" --direction right --cwd "$p" 2>/dev/null \
         | jq -r '.result.pane.pane_id // empty')
  if [[ -n "$np" ]]; then wtr_msg "${GRN}opened ${label} in a vertical split${RST}"
  else wtr_msg "${RED}split failed for ${label}${RST}"; fi
}

# ---------------------------------------------------------------------------
# Input & main loop
# ---------------------------------------------------------------------------
wtr_handle_key() {
  local key="$1" p
  # arrow keys arrive as ESC [ A/B; a bare ESC (nothing follows) quits.
  if [[ "$key" == $'\033' ]]; then
    local k2="" k3=""
    IFS= read -rsn1 -t 0.05 k2
    if [[ "$k2" == "[" ]]; then
      IFS= read -rsn1 -t 0.05 k3
      case "$k3" in A) key=k;; B) key=j;; *) return;; esac
    else
      WTR_QUIT=1; return
    fi
  fi
  case "$key" in
    k)              (( WTR_CURSOR-- )); wtr_clamp_cursor ;;
    j)              (( WTR_CURSOR++ )); wtr_clamp_cursor ;;
    ' '|$'\t')
      p="${WTR_PATHS[$WTR_CURSOR]:-}"
      [[ -z "$p" ]] && return
      if [[ -n "${WTR_SELECTED[$p]:-}" ]]; then unset 'WTR_SELECTED[$p]'; else WTR_SELECTED["$p"]=1; fi ;;
    d|$'\n'|$'\r')  wtr_do_delete ;;
    o)              wtr_do_open ;;
    r)              wtr_reload ;;
    q)              WTR_QUIT=1 ;;
  esac
}

wtr_teardown() {
  wtr_stop_scan
  [[ -n "$WTR_SCANFILE" ]] && rm -f "$WTR_SCANFILE"
  tput cnorm 2>/dev/null || true
  tput rmcup 2>/dev/null || true
}

wtr_loop() {
  trap wtr_teardown EXIT INT TERM
  tput smcup 2>/dev/null || true
  tput civis 2>/dev/null || true
  wtr_reload                        # fast list + background scan (non-blocking)
  local key was_scanning=0
  while (( ! WTR_QUIT )); do
    wtr_drain_scan                  # fold in whatever the scanner has produced
    wtr_draw
    # While a scan is running, poll input briefly so results keep streaming in and
    # keys stay responsive; when idle, block so we spend no CPU waiting.
    if wtr_scanning; then
      was_scanning=1
      if IFS= read -rsn1 -t 0.15 key; then
        wtr_handle_key "$key"
        # Consume any already-buffered keystrokes now so a burst of j/k during a
        # scan feels instant instead of one key per 0.15s poll.
        while IFS= read -rsn1 -t 0 key; do wtr_handle_key "$key"; done
      fi
    elif (( was_scanning )); then
      was_scanning=0; continue      # loop once more to drain + draw the final rows
    else
      IFS= read -rsn1 key || break
      wtr_handle_key "$key"
    fi
  done
  wtr_stop_scan
}

wtr_main() {
  if [[ "${1:-}" == -h || "${1:-}" == --help ]]; then
    sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    return 0
  fi
  if ! command -v git >/dev/null 2>&1; then
    printf 'wtrm: git not found\n' >&2; return 1
  fi
  WTR_SCANFILE=$(mktemp -t wtrm.scan) || { printf 'wtrm: could not create temp file\n' >&2; return 1; }
  wtr_setup_colors
  wtr_loop
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  wtr_main "$@"
fi
