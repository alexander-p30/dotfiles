#! /bin/sh
cd "$(chezmoi source-path)"
files_to_commit="$(git status --porcelain=v1 2>/dev/null | wc -l)"
upstream_commits="$(git rev-list @..@{u} --count)"
local_commits="$(git rev-list @{u}..@ --count)"
prompt="🏠"

chezmoi verify 2>/dev/null
retVal=$?
if [ $retVal -ne 0 ]; then prompt+="!"; fi
if [[ $files_to_commit -ne 0 ]]; then prompt+="+"; fi
if [[ $upstream_commits -ne 0 ]]; then prompt+="⇣"; fi
if [[ $local_commits -ne 0 ]]; then prompt+="⇡"; fi

echo $prompt
exit 0
