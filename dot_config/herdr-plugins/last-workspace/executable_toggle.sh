#!/usr/bin/env bash
# herdr "last-workspace" plugin — the toggle action (bound to prefix+shift+l).
#
# Focus the *previous* workspace (line 2 of the state file), tmux `last-window`
# style. Focusing fires workspace.focused, so on-focus.sh flips current/previous
# and the next invocation bounces back — true alternation between two spaces.

set -u

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/herdr/last-workspace"

prev=$(sed -n '2p' "$STATE" 2>/dev/null)
[ -z "$prev" ] && exit 0

# Only jump if that workspace still exists.
if herdr workspace list 2>/dev/null \
     | jq -e --arg w "$prev" '.result.workspaces[]? | select(.workspace_id == $w)' >/dev/null 2>&1; then
  herdr workspace focus "$prev" >/dev/null 2>&1
  # Landing on a workspace can leave its focused pane zoomed; make sure it isn't.
  fp=$(herdr api snapshot 2>/dev/null | jq -r '.result.snapshot.focused_pane_id // empty')
  [ -n "$fp" ] && herdr pane zoom --off --pane "$fp" >/dev/null 2>&1
fi
