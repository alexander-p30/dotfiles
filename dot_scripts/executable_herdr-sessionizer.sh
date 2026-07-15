#!/usr/bin/env bash
# Fuzzy-pick a project and open (or focus) it as a herdr workspace.
# Normally run from inside herdr (the login shell auto-attaches to the
# 'default' session), so the socket server is already up.

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(
      {
        find ~/Projects/remote ~/Projects/personal -mindepth 1 -maxdepth 1 -type d 2>/dev/null
        for dir in ~/Projects/remote/employ_workspace/*/; do
          [[ -e "${dir}.git" ]] && echo "${dir%/}"
        done
        echo "$HOME/.local/share/chezmoi"
      } | sed "s|^$HOME|~|" | fzf
    )
    selected="${selected/#\~/$HOME}"
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)

# Focus an existing workspace with this label; otherwise create one.
# Workspace objects in the snapshot are the ones carrying "tab_count".
existing=$(herdr api snapshot 2>/dev/null \
    | jq -r --arg n "$selected_name" \
        'first(.. | objects | select(has("tab_count") and .label == $n) | .workspace_id) // empty' 2>/dev/null)

if [[ -n $existing ]]; then
    herdr workspace focus "$existing"
else
    herdr workspace create --cwd "$selected" --label "$selected_name" --focus
fi
