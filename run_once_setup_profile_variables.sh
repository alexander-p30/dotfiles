#! /bin/bash
echo "============================"
echo ":: Setting up profile variables"

if grep -q "export EDITOR=/usr/bin/nvim"  "$File"; then
  echo "EDITOR not already set, setting it now"
  echo "export EDITOR=/usr/bin/nvim" >> ~/.profile
else
  echo "EDITOR already set, ignoring variable"
fi

if grep -q "export TERM=kitty" "$File"; then
  echo "TERM not already set, setting it now"
  echo "export TERM=kitty" >> ~/.profile
else
  echo "TERM already set, ignoring variable"
fi

