#!/bin/bash

if [ "$(file -b ~/.config/nvim)" = 'directory' ]; then
  cd "$(chezmoi source-path $1)"
else
  dirname "$($1)" | chezmoi source-path | cd
fi

chezmoi edit $1
