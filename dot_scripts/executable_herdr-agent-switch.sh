#!/usr/bin/env bash
# Fuzzy-switch between herdr agents, herdr-sidebar style:
#   <state> <session> · <tab>        <state · app>
# State glyphs follow herdr's convention: ◐ working (yellow), ✓ idle (green),
# ● done (cyan), ◼ blocked (red). Press an index digit (0-9) to jump straight to
# that row, or type to fuzzy-match (name or state word). Enter on no match is a
# no-op (won't close on a typo).

agents=$(herdr agent list 2>/dev/null) || exit 0
[[ -z $agents ]] && exit 0

wsmap=$(herdr workspace list 2>/dev/null | jq '[.result.workspaces[]? | {(.workspace_id): .label}] | add // {}')
tabmap=$(herdr tab list 2>/dev/null | jq '[.result.tabs[]? | {(.tab_id): .label}] | add // {}')
[[ -z $wsmap ]] && wsmap='{}'
[[ -z $tabmap ]] && tabmap='{}'

# terminal_id \t status \t session \t tab \t app
rows=$(jq -r --argjson ws "$wsmap" --argjson tb "$tabmap" '
  .result.agents[]?
  | [ .terminal_id,
      (.agent_status // "unknown"),
      ($ws[.workspace_id] // .workspace_id),
      ($tb[.tab_id]       // .tab_id),
      (.agent // "?") ] | @tsv' <<<"$agents")
[[ -z $rows ]] && exit 0

# Build the display: "<tid>\t[i] <glyph> <session · tab>   <dim>state · app</dim>".
# The glyph carries ANSI colour; the session·tab column is padded on plain text
# so the dim state column still lines up.
table=$(printf '%s\n' "$rows" | awk -F'\t' '
  function glyph(s) {
    if (s == "working") return "\033[93m◐\033[0m"
    if (s == "idle")    return "\033[92m✓\033[0m"
    if (s == "done")    return "\033[96m●\033[0m"
    if (s == "blocked") return "\033[91m◼\033[0m"
    return " "
  }
  { tid[NR]=$1; st[NR]=$2; name[NR]=$3 " · " $4; ds[NR]=$2 " · " $5
    if (length(name[NR]) > w) w=length(name[NR]); n=NR }
  END { for (r=1;r<=n;r++)
          printf "%s\t[%d] %s %-*s  \033[2m%s\033[0m\n", tid[r], r-1, glyph(st[r]), w, name[r], ds[r] }')

sel=$(fzf --ansi --delimiter='\t' --with-nth=2 --no-sort --reverse --prompt='agent> ' \
        --bind '0:pos(1)+accept,1:pos(2)+accept,2:pos(3)+accept,3:pos(4)+accept,4:pos(5)+accept,5:pos(6)+accept,6:pos(7)+accept,7:pos(8)+accept,8:pos(9)+accept,9:pos(10)+accept' \
        --bind 'enter:accept-non-empty' \
        <<<"$table")

if [[ -n $sel ]]; then
    herdr agent focus "${sel%%$'\t'*}"
    fp=$(herdr api snapshot 2>/dev/null | jq -r '.result.snapshot.focused_pane_id // empty')
    [[ -n $fp ]] && herdr pane zoom --off --pane "$fp" >/dev/null 2>&1
fi
