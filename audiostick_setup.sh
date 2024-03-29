#!/bin/bash

if [ "$(id -u)" != "0" ]; then
	echo "You need to run under sudo. Exiting."
	exit 1
fi

echo "Setting up AudioStick requirements."

apt install -y git mpd avahi-daemon
AUDIOSTICKDIR="./software/raspi"

echo "Backing up /boot/config.txt to ~/"
cp -v /boot/config.txt ~/config.txt_back

echo -n "Patching /boot/config.txt ..."
OVERLAY="dtoverlay=hifiberry-dac"
if grep -Fxq $OVERLAY /boot/config.txt
then
	echo "DAC's overlay already present. Skipping."
else
	echo "" >> /boot/config.txt
	echo $OVERLAY >> /boot/config.txt
fi
OVERLAY="dtoverlay=i2s-mmap"
if grep -Fxq $OVERLAY /boot/config.txt
then
        echo "MMS overlay already present. Skipping."
else
	echo $OVERLAY >> /boot/config.txt
fi

if grep -q -E "^dtparam=audio=on" /boot/config.txt; then
        sed -i "s|^dtparam=audio=on$|#dtparam=audio=on|" /boot/config.txt &> /dev/null
else
        echo "Default sound driver not loaded. Skipping."
fi

echo "Creating asound.conf ..."
ASOUND_F="/etc/asound.conf"
if [ -f $ASOUND_F ]; then
	echo "$ASOUND_F already exists. Skipping."
else
	cp -fv $AUDIOSTICKDIR/asound.conf $ASOUND_F
fi

echo "Setting up power management service..."
mkdir /opt/audiostick
cp $AUDIOSTICKDIR/audiostick_power.py /opt/audiostick
cp $AUDIOSTICKDIR/audiostick_power.service /etc/systemd/system
systemctl enable /etc/systemd/system/audiostick_power.service

echo "Installation complete!"
echo "When shutdown is complete, remove the power before restarting."
read -p "Continue? (y/n) " continue

if [ "$continue" = "y" ]; then
	shutdown -h now
else
	exit 1
fi
