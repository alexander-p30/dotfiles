#!/bin/sh

# Plugins
asdf plugin add erlang
asdf plugin add elixir
asdf plugin add golang
asdf plugin add nodejs
asdf plugin add ruby

# Erlang/Elixir
asdf install erlang 24.3.3
asdf global erlang 24.3.3
asdf install elixir 1.13.2-otp-24
asdf global elixir 1.13.2-otp-24

# Go
asdf install golang 1.18.1
asdf global golang 1.18.1

# Node
asdf install nodejs 10.23.0
asdf install nodejs lts
asdf global nodejs lts

# Ruby
asdf install ruby 3.0.2
asdf global ruby 3.0.2
