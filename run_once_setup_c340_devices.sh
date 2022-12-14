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
  echo -e "\t🟢 $FILE does not exist, creating it..."
  sudo touch $FILE
  sudo tee $FILE <<EOL
Section "Device"
  Identifier "Intel Graphics"
  Driver "intel"
  Option "TearFree" "true"
EndSection
EOL
else
  echo -e "⚠️  File $FILE already exists, aborting..."
fi

echo
echo ':: Setting up touchpad'
# Setup touchpad
FILE=/etc/X11/xorg.conf.d/90-touchpad.conf
if ! test -f "$FILE"; then
  echo -e "\t🟢 $FILE does not exist, creating it..."
  sudo touch $FILE
  sudo tee $FILE <<EOL
Section "InputClass"
  Identifier "touchpad"
  MatchIsTouchpad "on"
  Driver "libinput"
  Option "Tapping" "on"
  Option "NaturalScrolling" "on"
EndSection
EOL
else
  echo -e "⚠️  File $FILE already exists, aborting..."
fi

echo
echo ':: Setting up touchscreen'
# Setup touchscreen
FILE=/etc/X11/xorg.conf.d/99-no-touchscreen.conf
if ! test -f "$FILE"; then
  echo -e "\t🟢 $FILE does not exist, creating it..."
  sudo touch $FILE
  sudo tee $FILE <<EOL
Section "InputClass"
    Identifier         "Touchscreen catchall"
    MatchIsTouchscreen "on"
    Option "Ignore" "on"
EndSection
EOL
else
  echo -e "⚠️  File $FILE already exists, aborting..."
fi

echo
echo ':: Setting up i3 restart on HDMI connect'
FILE=/etc/udev/rules.d/51-update-xrandr.rules
if ! test -f "$FILE"; then
  echo -e "\t🟢 $FILE does not exist, creating it..."
  sudo touch $FILE
  sudo tee $FILE <<EOL
SUBSYSTEM=="drm", ACTION=="change", RUN+="i3 restart"
EOL
else
  echo -e "⚠️  File $FILE already exists, aborting..."
fi

echo
echo ':: Setting up backlight control for video group'
FILE=/etc/udev/rules.d/backlight.rules
if ! test -f "$FILE"; then
  echo -e "\t🟢 $FILE does not exist, creating it..."
  sudo touch $FILE
  sudo tee $FILE <<EOL
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"
EOL
else
  echo -e "⚠️  File $FILE already exists, aborting..."
fi

echo
echo ':: Adding user to video group'
if echo $(id -nG $USER) | grep -w "video"; then
  echo "⚠️  $USER already in video group"
else
  sudo usermod -aG video $USER
  echo "🟢 Added $USER to video group"
fi

echo
echo "🟢 Finished setting up C340 devices"
