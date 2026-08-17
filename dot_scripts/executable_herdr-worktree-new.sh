#!/usr/bin/env zsh
# herdr prefix+ctrl+w popup: pick a project, name a worktree, then open a tab on
# that project's herdr workspace that BUILDS the worktree live in its pane and
# turns into the claude session (+ a right-hand shell) when ready. The popup only
# gathers input and dispatches; the work runs in a normal, herdr-managed tab you
# can switch to and watch, or ignore ("minimise"). No background/detach needed.
source "${HOME}/.scripts/gt.zsh"

projects=$(_wt_projects)
[[ -z $projects ]] && { print "worktree: no projects found."; exit 1 }

# fzf shows just the label (field 1); fields 2/3 carry workspace id + repo dir.
sel=$(printf '%s\n' "$projects" | fzf -i --delimiter='\t' --with-nth=1 --no-sort \
        --reverse --prompt='project> ' --bind 'enter:accept-non-empty')
[[ -z $sel ]] && exit 0   # cancelled
proj=${sel%%$'\t'*}; rest=${sel#*$'\t'}; wsid=${rest%%$'\t'*}; repo=${rest#*$'\t'}

read -r "name?New worktree in ${proj}: "
name="${name#"${name%%[![:space:]]*}"}"   # ltrim
name="${name%"${name##*[![:space:]]}"}"   # rtrim
[[ -z $name ]] && { print "worktree: cancelled."; exit 0 }

# Last step: the prompt claude opens with. A gum textarea rather than `read` so
# the prompt can be written over several lines and freely edited before sending
# (claude takes multi-line input fine — send-text inserts soft breaks, and the
# single enter that follows submits the whole block as one message). Falls back
# to `read` where gum isn't installed. Empty accepts _wt_here's default.
if command -v gum >/dev/null 2>&1; then
  cprompt=$(gum write --height 8 --show-line-numbers \
              --header "Prompt for claude in ${proj} — enter sends · esc cancels · empty = default" \
              --placeholder 'Write the prompt claude should start with…') \
    || { print "worktree: cancelled."; exit 0 }
else
  read -r "cprompt?Prompt for claude (empty = default): "
fi
cprompt="${cprompt#"${cprompt%%[![:space:]]*}"}"   # ltrim
cprompt="${cprompt%"${cprompt##*[![:space:]]}"}"   # rtrim

# Open (and focus) the tab on the project's workspace, then run the builder in
# its pane. Passing the pane id lets the builder split its own right-hand shell.
pane=$(herdr tab create --workspace "$wsid" --cwd "$repo" --label "$(_wt_label "$name")" --focus 2>/dev/null \
         | jq -r '.result.root_pane.pane_id // empty')
[[ -z $pane ]] && { print "worktree: couldn't open a tab on ${proj}."; exit 1 }

# The prompt travels in a temp FILE, never on the command line. `pane run` types
# the command into a shell that is usually still sourcing .zshrc, so its tty is
# still in canonical mode — where macOS silently discards everything past
# MAX_CANON (1024 bytes) on a single line, the terminating newline included.
# ${(q)} makes that easy to reach: every line break costs 5 bytes ($'\n') and
# every space 2 (\ ), so a ~700-char prompt already builds a ~990-byte command.
# Once over, the prompt lost its tail *and* the command never ran, because the
# dropped bytes included the enter. A file keeps the command ~150 bytes flat, no
# matter how long the prompt is.
pfile=$(mktemp -t herdr-wt-prompt) || { print "worktree: couldn't create a temp file."; exit 1 }
print -r -- "$cprompt" > "$pfile"
herdr pane run "$pane" "source ${HOME}/.scripts/gt.zsh && _wt_here ${(q)pane} ${(q)name} ${(q)pfile}" >/dev/null 2>&1
