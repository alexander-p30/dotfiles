#! /bin/bash

echo "============================"
echo ":: Starting C340 device setup"
if [ "$(hostnamectl hostname)" == alexander-c340 ]; then
  echo "🟢 Successfully verified hostname, starting setup..."
else
  echo "⚠️  Not running script on c340, aborting..."
  exit 0
fi

# Setup intel videocard
echo ':: Installing intel videocard drivers'
## Install drivers
yay --needed -S lib32-mesa \
  lib32-mesa-demos \
  lib32-mesa-vdpau \
  libva-mesa-driver \
  mesa \
  mesa-demos \
  mesa-vdpau

## HW acceleration stuff
echo ':: Setting up HW acceleration'
yay --needed -S lib32-vulkan-intel \
    libva-intel-driver \
    vulkan-intel \
    xf86-video-intel

## Setup tear-free driver configs
echo
echo ':: Setting up tear-free driver configs'
FILE=/etc/X11/xorg.conf.d/20-intel.conf
if ! test -f "$FILE"; then
  echo -e "\t🟢 $(FILE) does not exist, creating it..."
  sudo touch $(FILE)
  sudo tee $(FILE) <<EOL
Section "Device"
  Identifier "Intel Graphics"
  Driver "intel"
  Option "TearFree" "true"
EndSection
EOL
else
  echo -e "⚠️  File already exists, aborting..."
fi

echo
echo ':: Setting up touchpad'
# Setup touchpad
FILE=/etc/X11/xorg.conf.d/90-touchpad.conf
if ! test -f "$FILE"; then
  echo -e "\t🟢 $(FILE) does not exist, creating it..."
  sudo touch $(FILE)
  sudo tee $(FILE) <<EOL
Section "InputClass"
  Identifier "touchpad"
  MatchIsTouchpad "on"
  Driver "libinput"
  Option "Tapping" "on"
  Option "NaturalScrolling" "on"
EndSection
EOL
else
  echo -e "⚠️  File already exists, aborting..."
fi

echo
echo ':: Setting up touchscreen'
# Setup touchscreen
FILE=/etc/X11/xorg.conf.d/99-no-touchscreen.conf
if ! test -f "$FILE"; then
  echo -e "\t🟢 $(FILE) does not exist, creating it..."
  sudo touch "$(FILE)"
  sudo tee "$(FILE)" <<EOL
Section "InputClass"
    Identifier         "Touchscreen catchall"
    MatchIsTouchscreen "on"
    Option "Ignore" "on"
EndSection
EOL
else
  echo -e "⚠️  File already exists, aborting..."
fi

echo "🟢 Finished setting up C340 devices"
