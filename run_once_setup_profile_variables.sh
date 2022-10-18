#! /bin/bash
echo "============================"
echo ":: Setting up profile variables"

File=$HOME/.profile

if grep -q "export EDITOR=/usr/bin/nvim"  "$File"; then
  echo "⚠️  EDITOR already set, ignoring variable"
else
  echo "🟢 EDITOR not already set, setting it now"
  echo "export EDITOR=/usr/bin/nvim" >> $File
fi

if grep -q "export TERM=kitty" "$File"; then
  echo "⚠️  TERM already set, ignoring variable"
else
  echo "🟢 TERM not already set, setting it now"
  echo "export TERM=kitty" >> $File
fi

