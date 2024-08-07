#!/bin/bash
set -e

help_msg="This is a simple arch deplyoment script. It's meant to be run after a fresh install of arch.\nBy default bare bones setup will be perfomed without setting up any sort of hardware specific software and QoL softwaren\n\n
			--hardware-specific\tWill install and setup nvidia drivers and additional firmware to get sound working on some computers\n\n
			--qol\tWill install some quality of life software"
HARDWARE_SPEC=0
QOL=0
DOTFILES="https://github.com/sentientbottleofwine/dotfiles"
SDDM_CONFIG_DIR="/etc/sddm.conf.d"
SDDM_DEFAULT_CONFIG="/usr/lib/sddm/sddm.conf.d/default.conf"

while [ ! -z "$1" ]; do
	case $1 in
		--hardware-specific)
			HARDWARE_SPEC=1
			;;
			
		--qol)
			QOL=1
			;;

		--help)
			echo -e "help_msg"
			exit 0
			;;

		*)
			echo "Unrecognized option: $1"
			exit 1
			;;
	esac
done

if [[ "$USER" = root ]]; then
	echo "This script is meant to be run by a normal user with sudo access"
	exit 1
fi

if [[ -z "$HOME" ]]; then
	echo 'This user has no home directory($HOME is unset/blank)'
	exit 1
fi

echo "Installing chosen packages"
echo "--------------------------\n" -e
yay -S --needed - < ./packages-bare-bones

if [[ $HARDWARE_SPEC -eq 1 ]]; then
	sudo pacman -S --needed - < ./package-hardware-specific
fi

if [[ $QOL -eq 1 ]]; then
	sudo pacman -S --needed - < ./package-QoL
fi

echo "Creating default xdg directories"
echo "--------------------------------\n" -e
xdg-user-dirs-update

echo "Cloning and deploying the dotfiles"
echo "----------------------------------\n" -e
git clone "$DOTFILES" ~/dotfiles
cd ~/dotfiles
stow .

echo "Setting up and enabling sddm"
echo "----------------------------\n" -e
sudo mkdir "$SDDM_CONFIG_DIR"
sudo cp "$SDDM_DEFAULT_CONFIG" "$SDDM_CONFIG_DIR"
sed "${SDDM_CONFIG_DIR}/default.conf" -e "s/User=.*/User=${USER}/"
sudo systemctl enable sddm.service

echo "Enabling pipewire"
echo "-----------------\n" -e
systemctl --user enable pipewire-pulse.service

echo "Enabling multilib repository"
echo "----------------------------\n" -e
sed -e 's/^#\[multilib\]$/[multilib]/' -e '\|^\[multilib\]$|{n;s|^#Include = /etc/pacman.d/mirrorlist$|Include = /etc/pacman.d/mirrorlist/|;}' -i /etc/pacman.conf

if [[ $HARDWARE_SPECIFIC -eq 1 ]]; then
	echo "Setting up nvidia"
	echo -e "--------------------------\n"
	chmod +x ./nvidia.sh && ./nvidia.sh
fi
