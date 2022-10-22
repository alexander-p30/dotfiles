#!/bin/sh

echo "============================"

echo ":: Installing yay"
pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
echo "🟢 Finished installing yay"

echo ":: Installing base packages"
yay --needed -S adwaita-maia \
    age \
    alacritty \
    alsa-firmware \
    alsa-plugins \
    alsa-utils \
    apparmor \
    arandr \
    autorandr \
    avr-gcc \
    avr-libc \
    avrdude \
    bat \
    betterlockscreen \
    binutils \
    bitwarden \
    blueman \
    bluez-utils \
    brave-bin \
    cantarell-fonts \
    chezmoi \
    clang \
    cmake \
    colordiff \
    coreutils \
    cpupower \
    diffutils \
    docker \
    dropbox \
    dropbox-cli \
    dunst \
    emacs \
    entr \
    epdfview \
    exa \
    fd \
    flameshot \
    git \
    gitflow-avh \
    google-chrome \
    gparted \
    gruvbox-material-gtk-theme-git \
    gruvbox-material-icon-theme-git \
    gucharmap \
    htop \
    i3-gaps \
    i3blocks \
    i3status \
    inotify-tools \
    insomnia-bin \
    jq \
    kitty \
    kmonad-git \
    lazygit \
    leafpad \
    lxappearance \
    lxinput \
    neofetch \
    neovim-nightly-bin \
    nerd-fonts-jetbrains-mono \
    nitrogen \
    nnn \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-compat \
    noto-fonts-emoji \
    papirus-maia-icon-theme \
    pavucontrol \
    picom-animations-git \
    playerctl \
    polybar \
    postman-bin \
    powerline-fonts \
    pulseaudio-ctl \
    rar \
    ripgrep \
    rofi \
    speedcrunch \
    spotify \
    terminus-font \
    thunar \
    thunar-dropbox \
    timeshift \
    tmux \
    tree \
    ttf-dejavu \
    ttf-droid \
    ttf-fira-code \
    ttf-font-awesome \
    ttf-inconsolata \
    ttf-indic-otf \
    ttf-iosevka-nerd \
    ttf-liberation \
    ttf-mac-fonts \
    ttf-monofur \
    vibrancy-icons-teal \
    xautolock \
    xcursor-breeze \
    xcursor-breeze-serie-obsidian \
    xcursor-chameleon-pearl \
    xcursor-maia \
    xmonad \
    xmonad-contrib \
    xsel \
    zsh

echo "🟢 Finished installing base packages"
