#! /bin/sh
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" ]; then exit 0; fi

cd "$(chezmoi source-path)"
upstream_commits="$(git rev-list @..@{u} --count)"
local_commits="$(git rev-list @{u}..@ --count)"
prompt="🏠"

chezmoi verify 2>/dev/null
retVal=$?
if [ $retVal -ne 0 ]; then prompt+="!"; fi
if [[ $upstream_commits -ne 0 ]]; then prompt+="⇣"; fi
if [[ $local_commits -ne 0 ]]; then prompt+="⇡"; fi

echo $prompt
exit 0
