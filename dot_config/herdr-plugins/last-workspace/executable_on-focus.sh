#!/usr/bin/env bash
# herdr "last-workspace" plugin — focus tracker.
#
# Runs on every workspace.focused event. Maintains a 2-line state file:
#   line 1 = current  (the workspace focused right now)
#   line 2 = previous (the workspace focused just before it)
# so toggle.sh can bounce between the two most-recently-focused workspaces,
# exactly like tmux `last-window`.
#
# Because herdr emits workspace.focused for ANY focus change (fzf picker,
# prefix+w, mouse, the toggle action, ...), this tracks all of them — not just
# key presses.

set -u

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/herdr/last-workspace"

# Extract the newly-focused workspace id from the event payload.
# workspace.focused carries the id at .data.workspace_id; nested/created events
# put it at .data.workspace.workspace_id (or .workspace_id / .id). Try them all.
new=$(printf '%s' "${HERDR_PLUGIN_EVENT_JSON:-}" \
  | jq -r '(.data.workspace.workspace_id // .data.workspace.id // .data.workspace_id // .workspace.workspace_id // .workspace_id) // empty' 2>/dev/null)

[ -z "$new" ] && exit 0

mkdir -p "$(dirname "$STATE")"

# Current is line 1 of the state file (line 2, the old previous, is recomputed).
cur=$(sed -n '1p' "$STATE" 2>/dev/null)

# Only record a change when the focused workspace actually differs. previous
# becomes the old current; current becomes the newly-focused workspace.
if [ "$new" != "$cur" ]; then
  printf '%s\n%s\n' "$new" "$cur" > "$STATE"
fi
