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

# Last step: which prompt claude opens with. One screen does both jobs: the
# three choices sit in the list, and whatever is typed or pasted on the query
# line becomes the {insert} of /goal-to-mergeable, so the common case needs no
# second step. fzf runs with --disabled so the typing never filters the list
# away; arrows (or ctrl-n/ctrl-p) move between the choices, enter confirms,
# esc cancels. The text is only read for the goal choice; the other two ignore it.
pfile=$(mktemp -t herdr-wt-prompt) || { print "worktree: couldn't create a temp file."; exit 1 }

# Find a neovim that actually runs, rather than trusting the name on PATH. The
# popup runs a non-interactive shell (no .zshrc) from whatever directory herdr
# hands it, so `nvim` there often resolves to mise's shim, and the shim exits
# with "No version is set for shim: nvim" outside a directory mise knows about.
# So each candidate is probed with --version and the first that answers wins:
# PATH, then what mise resolves from $HOME, then any installed neovim.
nvim_bin=""
try_nvim() { [[ -n $1 && -x $1 ]] && "$1" --version >/dev/null 2>&1 && { nvim_bin=$1; return 0 }; return 1 }
try_nvim "${commands[nvim]}" \
  || try_nvim "$(cd "$HOME" && ${commands[mise]:-$HOME/.local/bin/mise} which nvim 2>/dev/null)" \
  || { for c in "$HOME"/.local/share/mise/installs/neovim/*/bin/nvim(N); do try_nvim "$c" && break; done }

# edit_prompt [seed] — put <seed> in $pfile, edit it, leave the result in
# $cprompt; returns 1 when the edit was cancelled. Neovim rather than a textarea
# widget, because these prompts get long and get rewritten, and here they get
# the usual motions, undo and plugins. `wrap` keeps long lines readable in a
# popup this narrow. The buffer IS the temp file that travels to _wt_here (see
# the note below), so nothing is retyped or re-quoted: write and quit to send,
# `:cq` cancels. Empty is a real answer — claude then opens with no prompt at
# all. Falls back to gum, then `read`, where nvim is missing.
edit_prompt() {
  local seed=${1-}
  print -rn -- "$seed" > "$pfile"
  if [[ -n $nvim_bin ]]; then
    "$nvim_bin" \
      -c 'setlocal filetype=markdown wrap linebreak' \
      -c 'setlocal winbar=\ prompt\ for\ claude\ in\ '"${(q)proj}"'\ ·\ :wq\ sends\ ·\ :cq\ cancels' \
      -c 'normal! G$' -c 'startinsert!' \
      "$pfile" || return 1
    cprompt=$(<"$pfile")
  elif command -v gum >/dev/null 2>&1; then
    cprompt=$(gum write --height 8 --show-line-numbers --value "$seed" \
                --header "Prompt for claude in ${proj} · enter sends · esc cancels" \
                --placeholder 'Write the prompt claude should start with…') || return 1
  else
    read -r "cprompt?Prompt for claude: "
    cprompt="${seed}${cprompt}"
  fi
  return 0
}

goal_cmd='/goal-to-mergeable'
pick=$(print -l \
         "goal      ${goal_cmd} <the text typed on the line above>" \
         'default   the Linear prompt: read the issue, implement it, open an MR, babysit it' \
         'write     write the prompt by hand in neovim' \
       | fzf --disabled --print-query --no-sort --reverse \
             --prompt='goal> ' \
             --header="Prompt for claude in ${proj} · type or paste the goal, then pick a line") \
  || { print "worktree: cancelled."; rm -f "$pfile"; exit 0 }
insert=${pick%%$'\n'*}                              # the query line
insert="${insert#"${insert%%[![:space:]]*}"}"       # ltrim
insert="${insert%"${insert##*[![:space:]]}"}"       # rtrim
case ${${pick#*$'\n'}%% *} in
  goal)    # Nothing typed? Open the editor seeded with the command rather than
           # sending a bare /goal-to-mergeable with no goal behind it.
           if [[ -n $insert ]]; then
             cprompt="${goal_cmd} ${insert}"
           else
             edit_prompt "${goal_cmd} " || { print "worktree: cancelled."; rm -f "$pfile"; exit 0 }
           fi ;;
  default) cprompt=$(_wt_default_prompt) ;;
  *)       edit_prompt || { print "worktree: cancelled."; rm -f "$pfile"; exit 0 } ;;
esac
cprompt="${cprompt#"${cprompt%%[![:space:]]*}"}"   # ltrim
cprompt="${cprompt%"${cprompt##*[![:space:]]}"}"   # rtrim

# Open (and focus) the tab on the project's workspace, then run the builder in
# its pane. Passing the pane id lets the builder split its own right-hand shell.
pane=$(herdr tab create --workspace "$wsid" --cwd "$repo" --label "$(_wt_label "$name")" --focus 2>/dev/null \
         | jq -r '.result.root_pane.pane_id // empty')
[[ -z $pane ]] && { print "worktree: couldn't open a tab on ${proj}."; rm -f "$pfile"; exit 1 }

# The prompt travels in a temp FILE, never on the command line. `pane run` types
# the command into a shell that is usually still sourcing .zshrc, so its tty is
# still in canonical mode — where macOS silently discards everything past
# MAX_CANON (1024 bytes) on a single line, the terminating newline included.
# ${(q)} makes that easy to reach: every line break costs 5 bytes ($'\n') and
# every space 2 (\ ), so a ~700-char prompt already builds a ~990-byte command.
# Once over, the prompt lost its tail *and* the command never ran, because the
# dropped bytes included the enter. A file keeps the command ~150 bytes flat, no
# matter how long the prompt is. (It is the same file the editor
# used above; this only writes the final, trimmed text back over it.)
print -r -- "$cprompt" > "$pfile"

# Guard the dispatch against a pane-startup race. `pane run` types the builder
# command into the just-created shell while it may still be sourcing .zshrc
# (mise, direnv, starship, plugins). If the shell isn't reading its command line
# yet — or a stray keystroke lands on the freshly focused pane — the command is
# mangled and the worktree/prompt silently never happens. (The `gt -n` path
# dodges this: a split + setup run buys the shell time before it launches claude;
# here we'd otherwise dispatch at once.) So handshake first: clear any partial
# line, have the shell echo a sentinel, and wait to see it in the OUTPUT — the
# $(( )) keeps the literal 42 out of the *typed* command, so a match proves the
# shell finished .zshrc and is actually executing commands, not that `pane run`
# merely echoed our text. Only then dispatch the builder onto a ready line. If
# the handshake times out (shell wedged), we still dispatch — no worse than before.
ready="42_wt_ready_$$"
herdr pane send-keys "$pane" C-u >/dev/null 2>&1
herdr pane run "$pane" "print -r -- \$((6 * 7))_wt_ready_$$" >/dev/null 2>&1
herdr pane wait-output "$pane" --match "$ready" --timeout 10000 >/dev/null 2>&1
herdr pane send-keys "$pane" C-u >/dev/null 2>&1
herdr pane run "$pane" "clear; source ${HOME}/.scripts/gt.zsh && _wt_here ${(q)pane} ${(q)name} ${(q)pfile}" >/dev/null 2>&1
