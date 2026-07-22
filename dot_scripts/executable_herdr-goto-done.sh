#!/usr/bin/env bash
# Jump to the agent that most needs you, by attention priority
# (BLOCKED > DONE > WORKING; idle agents are skipped).
#
# From anywhere below the top tier — a working agent while something is blocked,
# an idle pane, or a non-agent pane — jump straight to the top of the queue.
# Only when you're ALREADY on an agent at the top priority tier does a press
# advance to the next agent in the queue (wrapping at the end), so repeated
# presses walk the blocked agents (or, once those clear, the working ones)
# without ever being pulled down a tier while a higher one still needs you.
# No-op if nothing needs attention. Bound via [[keys.command]] type="shell".
# (Sidebar-exact stepping is a separate binding: next_agent / previous_agent.)

al=$(herdr agent list 2>/dev/null) || exit 0

# Candidate pane_ids in attention-priority order: all blocked, then done,
# then working. Idle agents are excluded — nothing there needs you.
# (herdr 0.7.5+: `agent focus` targets a pane_id, not a terminal_id.)
cands=$(jq -r '
  (.result.agents // []) as $a
  | ([ $a[] | select(.agent_status == "blocked") | .pane_id ]
   + [ $a[] | select(.agent_status == "done")    | .pane_id ]
   + [ $a[] | select(.agent_status == "working") | .pane_id ])[]
' <<<"$al")
[[ -z $cands ]] && exit 0

# Status of the highest-priority tier that has any agent, and the status of the
# currently-focused pane (empty when the focused pane isn't an agent).
top_status=$(jq -r '
  (.result.agents // []) as $a
  | if   any($a[]; .agent_status == "blocked") then "blocked"
    elif any($a[]; .agent_status == "done")    then "done"
    elif any($a[]; .agent_status == "working") then "working"
    else "" end
' <<<"$al")
cur=$(jq -r 'first(.result.agents[]? | select(.focused == true) | .pane_id) // empty' <<<"$al")
cur_status=$(jq -r 'first(.result.agents[]? | select(.focused == true) | .agent_status) // empty' <<<"$al")

if [[ -n $cur_status && $cur_status == "$top_status" ]]; then
  # Already on a top-tier agent: advance to the next candidate, wrapping at the
  # end. cur is guaranteed to be in the queue here (its tier is the top tier).
  target=$(printf '%s\n' "$cands" | awk -v cur="$cur" '
    { d[NR] = $0; n = NR }
    END {
      tgt = d[1]
      for (i = 1; i <= n; i++) if (d[i] == cur) { tgt = (i < n ? d[i+1] : d[1]); break }
      print tgt
    }')
else
  # Below the top tier (working while something is blocked/done, idle, or a
  # non-agent pane): jump to the highest-priority agent.
  target=$(printf '%s\n' "$cands" | head -n1)
fi
[[ -z $target ]] && exit 0

herdr agent focus "$target" >/dev/null 2>&1
# focus can zoom the landed pane; we only want it focused
fp=$(herdr api snapshot 2>/dev/null | jq -r '.result.snapshot.focused_pane_id // empty')
[[ -n $fp ]] && herdr pane zoom --off --pane "$fp" >/dev/null 2>&1
