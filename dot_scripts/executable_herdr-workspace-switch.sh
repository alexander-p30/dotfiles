#!/usr/bin/env bash
# Fuzzy "go to" picker over herdr workspaces AND their tabs. Type to fuzzy-filter
# names; a state glyph + word marks anything with an
# active agent, following herdr's convention: ◐ working (yellow), ✓ idle (green),
# ● done (cyan), ◼ blocked (red). Tab rows show the dim "workspace:N" (N = the
# tab's 1-based position) FIRST, then the tab label ("tiger:1 main"), so the two
# run together as you type — e.g. "tiger1" or "neoma" matches. Enter on no match
# is a no-op. Workspace rows focus the workspace; tab rows focus that tab.

ws=$(herdr workspace list 2>/dev/null) || exit 0
[[ -z $ws ]] && exit 0
tabs=$(herdr tab list 2>/dev/null)
[[ -z $tabs ]] && tabs='{"result":{"tabs":[]}}'

esc=$'\033'  # keep ANSI escapes out of the jq source; inject ESC as data instead

# Emit "<target>\t<display>" per row, workspaces each followed by their tabs.
rows=$(jq -rn --arg esc "$esc" --argjson ws "$ws" --argjson tabs "$tabs" '
  def glyph($s):
    if   $s == "working" then $esc + "[93m◐" + $esc + "[0m"
    elif $s == "idle"    then $esc + "[92m✓" + $esc + "[0m"
    elif $s == "done"    then $esc + "[96m●" + $esc + "[0m"
    elif $s == "blocked" then $esc + "[91m◼" + $esc + "[0m"
    else " " end;
  def dim($t): $esc + "[2m" + $t + $esc + "[0m";
  def stateword($s):
    if ($s == "working" or $s == "idle" or $s == "done" or $s == "blocked") then $s else "" end;
  ($ws.result.workspaces // []) as $wl
  | ($tabs.result.tabs // []) as $tl
  | [ range(0; ($wl|length)) as $i
      | $wl[$i] as $w
      | ( "ws:" + $w.workspace_id + "\t" + glyph($w.agent_status) + " " + $w.label
          + ( stateword($w.agent_status) | if . == "" then "" else "  " + dim(.) end ) ),
        ( [ $tl[] | select(.workspace_id == $w.workspace_id) ] as $wt
          | range(0; ($wt|length)) as $j
          | $wt[$j] as $t
          | "tab:" + $t.tab_id + "\t    " + glyph($t.agent_status) + " "
              + dim($w.label + ":" + (($j + 1) | tostring)) + " " + $t.label
              + ( stateword($t.agent_status) | if . == "" then "" else "  " + dim(.) end ) )
    ] | .[]')
[[ -z $rows ]] && exit 0

sel=$(fzf --ansi --delimiter='\t' --with-nth=2 --no-sort --reverse --prompt='go> ' \
        --bind 'enter:accept-non-empty' <<<"$rows")
[[ -z $sel ]] && exit 0

target=${sel%%$'\t'*}
case $target in
  ws:*)  herdr workspace focus "${target#ws:}" ;;
  tab:*) herdr tab focus "${target#tab:}" ;;
esac
# focus can zoom the landed-on pane; we only want it focused, not zoomed
fp=$(herdr api snapshot 2>/dev/null | jq -r '.result.snapshot.focused_pane_id // empty')
[[ -n $fp ]] && herdr pane zoom --off --pane "$fp" >/dev/null 2>&1
