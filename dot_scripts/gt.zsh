# vim:syntax=bash
# gt — fuzzy-jump to a repo/worktree (bound to Ctrl-f in .zshrc). Worktrees nest
# under their <repo>-worktrees dir; green ● = open workspace/agent: selecting one
# confirms before focusing it in herdr (No re-opens the picker), else it cd's.
#
# gt -n / --new (bound to Ctrl-n): same picker, but an unopened dir is opened in
# a fresh herdr tab (labelled its leaf) with claude running left + a shell right,
# instead of cd'ing the current shell. An already-open dir still focuses.
#
# gt [-n] <dir>: skip the picker and act on <dir> directly (used by `worktree`).

# _gt_go <target> — act on one chosen dir. Reads $new/$snap/$agents from the
# calling gt() via zsh dynamic scope. Returns 2 when the user declines focusing
# an already-open dir (so the picker can re-prompt); 0 otherwise.
_gt_go() {
  local target=$1 tid wsid name fp pane rpane setup ok
  tid=$(jq -r --arg d "$target" 'first(.result.agents[]? | select(.cwd == $d or .foreground_cwd == $d) | .terminal_id) // empty' <<<"$agents")
  wsid=""
  if [[ -z $tid ]]; then
    name=${target:t}; name=${name//./_}
    wsid=$(jq -r --arg n "$name" 'first(.. | objects | select(has("tab_count") and .label == $n) | .workspace_id) // empty' <<<"$snap")
    [[ -n $wsid ]] && tid=$(jq -r --arg w "$wsid" 'first(.result.agents[]? | select(.workspace_id == $w) | .terminal_id) // empty' <<<"$agents")
  fi

  # Only the interactive picker (focus=1) does the "already open → confirm+focus"
  # dance; --no-focus (background worktree) always creates a fresh tab and never
  # prompts — a `read -q` there would crash the detached, non-interactive shell.
  if (( focus )) && [[ -n $tid || -n $wsid ]]; then
    if read -q "ok?Focus ${target:t} (already open)? [y/N] "; then
      echo
      if [[ -n $tid ]]; then herdr agent focus "$tid" >/dev/null 2>&1
      else herdr workspace focus "$wsid" >/dev/null 2>&1; fi
      fp=$(herdr api snapshot 2>/dev/null | jq -r '.result.snapshot.focused_pane_id // empty')
      [[ -n $fp ]] && herdr pane zoom --off --pane "$fp" >/dev/null 2>&1
      return 0
    fi
    echo
    return 2   # declined -> caller may re-pick
  elif (( new )); then
    # Not open + -n: fresh tab (leaf label, cwd=target), claude left, shell right.
    # --focus unless told otherwise; --workspace pins the tab to a herdr workspace.
    local createargs=(--cwd "$target" --label "$(_wt_label "${target:t}")")
    (( focus ))      && createargs+=(--focus)
    [[ -n $wsflag ]] && createargs+=(--workspace "$wsflag")
    pane=$(herdr tab create "${createargs[@]}" 2>/dev/null \
             | jq -r '.result.root_pane.pane_id // empty')
    [[ -z $pane ]] && { echo "gt: couldn't open a tab for ${target:t}"; return 0; }
    rpane=$(herdr pane split --pane "$pane" --direction right --cwd "$target" 2>/dev/null \
              | jq -r '.result.pane.pane_id // empty')
    # Bootstrap the right pane: trust the env (from apps/tiger if this repo has one).
    setup='direnv allow && mise trust'
    [[ -d $target/apps/tiger ]] && setup="cd apps/tiger && $setup"
    [[ -n $rpane ]] && herdr pane run "$rpane" "$setup" >/dev/null 2>&1
    # Clear the line first so any stray keystroke typed into the just-focused
    # pane can't merge with and mangle the 'claude' command.
    herdr pane send-keys "$pane" C-u >/dev/null 2>&1
    herdr pane run "$pane" claude >/dev/null 2>&1   # focus stays on the (left) claude pane
    return 0
  else
    cd "$target"; return 0
  fi
}

gt() {
  local new=0 focus=1 wsflag=""
  while true; do
    case $1 in
      -n|--new)    new=1; shift ;;
      --no-focus)  focus=0; shift ;;       # don't steal focus (used by `worktree`)
      --workspace) wsflag=$2; shift 2 ;;   # pin the new tab to a herdr workspace id
      *) break ;;
    esac
  done
  local remote="$HOME/Projects/remote" ws repos_yaml snap agents labels acwds paths rows query="" out sel target
  ws="$remote/employ_workspace"; repos_yaml="$ws/config/repos.yaml"
  snap=$(herdr api snapshot 2>/dev/null)
  agents=$(herdr agent list 2>/dev/null)

  # Direct path mode: `gt [-n] <dir>` skips the picker entirely.
  if [[ -n $1 ]]; then
    target=${1:A}
    [[ -d $target ]] || { echo "gt: no such directory: $1"; return 1; }
    _gt_go "$target"
    return
  fi

  labels=$(jq -r '[.. | objects | select(has("tab_count")) | .label] | .[]' <<<"$snap" 2>/dev/null)
  acwds=$(jq -r '.result.agents[]? | (.cwd, .foreground_cwd) | select(. != null)' <<<"$agents" 2>/dev/null)

  paths=$(
    [[ -d "$ws" ]] && echo "$ws"
    for base in "$remote" "$ws"; do
      find "$base" -mindepth 1 -maxdepth 1 -type d -name '*worktrees*' \
        -exec find {} -mindepth 1 -maxdepth 1 -type d \; 2>/dev/null
    done
    [[ -f "$repos_yaml" ]] && sed -n 's/^[[:space:]]*-[[:space:]]*key:[[:space:]]*//p' "$repos_yaml" \
      | while read -r key; do [[ -d "$ws/$key" ]] && echo "$ws/$key"; done
  )

  rows=$(
    { printf '%s\n' "$labels" | sed 's|^|@L|'
      printf '%s\n' "$acwds"  | sed 's|^|@C|'
      printf '%s\n' "$paths"; } | awk '
      function norm(s) { gsub(/\./, "_", s); return s }
      function mark(p,   bn) { bn = p; sub(/.*\//, "", bn); return (norm(bn) in lab || p in cwd) ? "\033[32m●\033[0m " : "  " }
      BEGIN { D = "\033[2m"; Z = "\033[0m" }
      /^@L/ { l = substr($0, 3); if (l != "") lab[l] = 1; next }
      /^@C/ { c = substr($0, 3); if (c != "") cwd[c] = 1; next }
      {
        p = $0; if (p == "") next
        b = p; sub(/.*\//, "", b)
        parent = p; sub(/\/[^\/]+$/, "", parent); pn = parent; sub(/.*\//, "", pn)
        if (pn ~ /-worktrees$/) {
          if (!(parent in seen)) { seen[parent] = 1; print "B" pn "0\t" parent "\t" mark(parent) D pn Z }
          print "B" pn "1" b "\t" p "\t    " mark(p) D pn " ·" Z " " b
        } else {
          print "A" b "\t" p "\t" mark(p) b
        }
      }' | sort | cut -f2-
  )

  while true; do
    out=$(printf '%s\n' "$rows" | fzf --ansi --delimiter='\t' --with-nth=2 --no-sort --reverse \
            --query="$query" --print-query)
    query=${out%%$'\n'*}
    sel=${out#*$'\n'}
    [[ $sel == "$out" || -z $sel ]] && return   # Esc / no match
    target=${sel%%$'\t'*}

    _gt_go "$target"
    (( $? == 2 )) && continue   # declined focus -> loop back to fzf, same query
    return
  done
}

# _wt_make <branch> — create a worktree for <branch> using THIS repo's own
# tooling (the same scripts the project's `worktree` skill runs), so it lands
# under ../<repo>-worktrees/ with CoW artifact cloning + secret copying. A bare
# `git worktree add <branch>` would instead nest it *inside* the repo, so we call
# the script directly rather than hoping a headless claude picks the right one.
#
# The tooling lives at <root>/devtools/ (neo) or a nested app dir (tiger keeps it
# in apps/tiger/devtools/); we run it from that dir, as its skill documents. The
# script finds the git root itself and creates the worktree at ../<repo>-worktrees/
# regardless. Progress goes to stderr (visible); the new path prints on stdout
# (found by diffing `git worktree list`, so wherever the script actually puts it).
_wt_make() {
  local branch=$1 before after root tooldir d
  local caf=()
  (( $+commands[caffeinate] )) && caf=(caffeinate -sumi)   # keep the Mac awake for the (slow) build; the assertion is released the moment the build exits
  before=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | sort)
  tooldir=""
  for d in . apps/*(N/); do
    [[ -f $d/devtools/cow_worktree.exs || -f $d/devtools/make_worktree.sh ]] && { tooldir=$d; break }
  done
  (   # subshell so the cd doesn't leak back to the caller
    if [[ -n $tooldir ]]; then
      cd "$tooldir"
      if [[ -f devtools/cow_worktree.exs ]]; then
        $caf elixir devtools/cow_worktree.exs "$branch"
      else
        $caf bash devtools/make_worktree.sh "$branch"
      fi
    else
      root=$(git rev-parse --show-toplevel)
      $caf git worktree add "${root:h}/${root:t}-worktrees/$branch" -b "$branch"
    fi
  ) >&2
  after=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | sort)
  comm -13 <(print -r -- "$before") <(print -r -- "$after") | head -1
}

# worktree [--workspace ID] <branch> — create a worktree via _wt_make, then open
# it in a fresh herdr tab with `gt -n`. (The prefix+ctrl+w popup uses _wt_here
# instead, to build in-place.)
worktree() {
  local wsid="" branch loc wsargs
  while true; do
    case $1 in
      --workspace) wsid=$2; shift 2 ;;   # herdr workspace id the tab should land on
      *) break ;;
    esac
  done
  branch=$1
  [[ -z $branch ]] && { echo "usage: worktree [--workspace ID] <branch-name>" >&2; return 1; }
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { echo "worktree: run this from inside a git repository" >&2; return 1; }

  echo "worktree: creating '$branch'…"
  loc=$(_wt_make "$branch")
  [[ -n $loc && -d $loc ]] || { echo "worktree: couldn't create the worktree" >&2; return 1; }
  echo "worktree: opening $loc"
  wsargs=(); [[ -n $wsid ]] && wsargs=(--workspace "$wsid")
  gt -n --no-focus "${wsargs[@]}" "$loc"   # no focus grab; pin to the project workspace
  _wt_notify "Worktree ready: $branch" "$loc"
}

# _wt_notify <title> <body> — native macOS banner (herdr toasts are delivery=off).
# Fires only when a worktree finishes: its tab may be on another workspace, or you
# may have switched away while it built. argv form avoids quote-escaping.
_wt_notify() {
  osascript - "$1" "$2" >/dev/null 2>&1 <<'OSA'
on run argv
  display notification (item 2 of argv) with title (item 1 of argv) sound name "Glass"
end run
OSA
}

# _wt_projects — emit "<label>\t<workspace_id>\t<repo_dir>" for each herdr
# workspace that maps to a real repo under employ_workspace. Ties the project
# picker's choice to both where the worktree is made and where its tab lands.
_wt_projects() {
  local ws="$HOME/Projects/remote/employ_workspace" label wsid repo
  herdr workspace list 2>/dev/null \
    | jq -r '.result.workspaces[]? | "\(.label)\t\(.workspace_id)"' \
    | while IFS=$'\t' read -r label wsid; do
        [[ $label == employ_workspace ]] && repo="$ws" || repo="$ws/$label"
        [[ -d $repo/.git || -f $repo/.git ]] && printf '%s\t%s\t%s\n' "$label" "$wsid" "$repo"
      done
}

# _wt_label <name> — if <name> leads with a Linear issue code (<letters>-<digits>-),
# strip it so tab labels read cleanly; otherwise pass it through unchanged:
#   neo-5749-ensure-every-sentry-event -> ensure-every-sentry-event
#   my-feature                         -> my-feature
_wt_label() { print -r -- "$1" | sed -E 's/^[[:alpha:]]+-[[:digit:]]+-//'; }

# _wt_here <pane_id> <branch> — runs INSIDE the pane's own interactive shell (so
# `cd` sticks and `claude` lands here), started in the repo. Shows progress while
# the worktree is built, then turns THIS pane into the claude session with a
# right-hand shell. This is what the prefix+ctrl+w popup dispatches: the tab is
# the live progress view — switch to it to watch, switch away to "minimise". No
# background/detach needed; herdr keeps the pane alive on its own.
_wt_here() {
  local pane=$1 branch=$2 loc rpane setup
  print -P "%F{yellow}⏳ creating worktree '$branch' in ${PWD:t}…%f"
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    print -P "%F{red}✗ not inside a git repository%f"; return 1
  }
  # Runs the repo's own worktree tooling; its output streams to this pane.
  loc=$(_wt_make "$branch")
  if [[ -z $loc || ! -d $loc ]]; then
    print -P "%F{red}✗ worktree not created — see the output above%f"; return 1
  fi
  print -P "%F{green}✓ created at $loc%f"
  cd "$loc"
  setup='direnv allow && mise trust'
  [[ -d $loc/apps/tiger ]] && setup="cd apps/tiger && $setup"
  rpane=$(herdr pane split --pane "$pane" --direction right --cwd "$loc" 2>/dev/null \
            | jq -r '.result.pane.pane_id // empty')
  [[ -n $rpane ]] && herdr pane run "$rpane" "$setup" >/dev/null 2>&1
  _wt_notify "Worktree ready: $branch" "$loc"
  # If the branch carries a Linear code, pre-fill (but don't send) a prompt in
  # claude's input box once its UI is ready. Sent from a backgrounded job because
  # `claude` below runs in the foreground; send-text types without pressing Enter.
  if [[ $(_wt_label "$branch") != "$branch" ]]; then
    ( herdr pane wait-output "$pane" --match "shift+tab" --timeout 15000 >/dev/null 2>&1
      herdr pane send-text "$pane" "See the linear issue associated with this branch and implement it" ) &!
  fi
  claude
}
