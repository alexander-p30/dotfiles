# vim:syntax=bash
# gt — fuzzy-jump to a repo/worktree (bound to Ctrl-f in .zshrc). Worktrees nest
# under their <repo>-worktrees dir; green ● = open workspace/agent: selecting one
# confirms before focusing it in herdr (No re-opens the picker), else it cd's.
gt() {
  local remote="$HOME/Projects/remote" ws repos_yaml snap agents labels acwds paths rows query="" out sel target tid name wsid fp ok
  ws="$remote/employ_workspace"; repos_yaml="$ws/config/repos.yaml"
  snap=$(herdr api snapshot 2>/dev/null)
  agents=$(herdr agent list 2>/dev/null)
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

    tid=$(jq -r --arg d "$target" 'first(.result.agents[]? | select(.cwd == $d or .foreground_cwd == $d) | .terminal_id) // empty' <<<"$agents")
    wsid=""
    if [[ -z $tid ]]; then
      name=${target:t}; name=${name//./_}
      wsid=$(jq -r --arg n "$name" 'first(.. | objects | select(has("tab_count") and .label == $n) | .workspace_id) // empty' <<<"$snap")
      [[ -n $wsid ]] && tid=$(jq -r --arg w "$wsid" 'first(.result.agents[]? | select(.workspace_id == $w) | .terminal_id) // empty' <<<"$agents")
    fi

    if [[ -n $tid || -n $wsid ]]; then
      if read -q "ok?Focus ${target:t} (already open)? [y/N] "; then
        echo
        if [[ -n $tid ]]; then herdr agent focus "$tid" >/dev/null 2>&1
        else herdr workspace focus "$wsid" >/dev/null 2>&1; fi
        fp=$(herdr api snapshot 2>/dev/null | jq -r '.result.snapshot.focused_pane_id // empty')
        [[ -n $fp ]] && herdr pane zoom --off --pane "$fp" >/dev/null 2>&1
        return
      fi
      echo   # No -> loop back to fzf with the same query
    else
      cd "$target"; return
    fi
  done
}
