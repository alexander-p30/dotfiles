#! /bin/bash

cp "$(chezmoi source-path)/dot_scripts/executable_chezmoi_status.sh" ~/.local/bin/chezmoi_status
chmod +x ~/.local/bin/chezmoi_status
cp "$(chezmoi source-path)/dot_scripts/executable_cedit.sh" ~/.local/bin/cedit
chmod +x ~/.local/bin/cedit
cp "$(chezmoi source-path)/dot_scripts/executable_i3exit.sh" ~/.local/bin/i3exit
chmod +x ~/.local/bin/i3exit
