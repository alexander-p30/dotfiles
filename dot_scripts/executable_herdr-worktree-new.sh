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

# Open (and focus) the tab on the project's workspace, then run the builder in
# its pane. Passing the pane id lets the builder split its own right-hand shell.
pane=$(herdr tab create --workspace "$wsid" --cwd "$repo" --label "$(_wt_label "$name")" --focus 2>/dev/null \
         | jq -r '.result.root_pane.pane_id // empty')
[[ -z $pane ]] && { print "worktree: couldn't open a tab on ${proj}."; exit 1 }
herdr pane run "$pane" "source ${HOME}/.scripts/gt.zsh && _wt_here ${(q)pane} ${(q)name}" >/dev/null 2>&1
