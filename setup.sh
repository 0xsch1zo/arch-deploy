#!/bin/bash
set -e

_HELP_MSG="This is a simple arch deplyoment script. It's meant to be run after a fresh install of arch.
By default bare bones setup will be perfomed without setting up any sort of hardware specific software and QoL softwaren\n\n
		--hardware-specific		Will install and setup nvidia drivers and additional firmware to get sound working on some computers\n\n
		--qol					Will install some quality of life software"
_HARDWARE_SPEC=0
_QOL=0
_DOTFILES="https://github.com/sentientbottleofwine/dotfiles"
_DOTFILES_DIR="${HOME}/dotfiles"
_SDDM_CONFIG_DIR="/etc/sddm.conf.d"
_SDDM_DEFAULT_CONFIG="/usr/lib/sddm/sddm.conf.d/default.conf"
_COLORSCHEME="tokyo-night"
_KVANTUM_THEME="https://github.com/sentientbottleofwine/Kvantum-Tokyo-Night"
_KVANTUM_THEME_NAME="Kvantum-Tokyo-Night"
_KVANTUM_DIR="${HOME}/.config/Kvantum"
_GTK_THEME="https://github.com/sentientbottleofwine/Tokyonight-GTK-Theme-new-colors"
_GTK_THEME_NAME="Tokyonight-GTK-Theme-new-colors"
_GTK_INSTALL_SCRIPT="themes/install.sh"
_GTK_BUILD_SCRIPT="themes/build.sh"
_GTK_INSTALL_FLAGS="--tweaks macos"

while [ ! -z "$1" ]; do
	case $1 in
		--hardware-specific)
			_HARDWARE_SPEC=1
			shift
			;;
			
		--qol)
			_QOL=1
			shift
			;;

		--help)
			echo -e "$_HELP_MSG"
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


if [[ -z "$(pacman -Qs yay)" ]]; then
	echo -ne "\033[32;40m"
	echo "Installing yay"
	echo -e "\033[97;40m"
	
	sudo pacman -S base-devel go
	git clone https://aur.archlinux.org/yay.git
	cd yay
	makepkg
	package=`ls -1 | grep yay | grep -v debug | grep zst`
	sudo pacman -U "$package"
	cd ../
fi

echo -ne "\033[32;40m"
echo "Installing chosen packages"
echo -e "\033[97;40m"

yay -S --needed - < ./packages-bare-bones

if [[ $_HARDWARE_SPEC -eq 1 ]]; then
	sudo pacman -S --needed - < ./packages-hardware-specific
fi

if [[ $_QOL -eq 1 ]]; then
	yay -S --needed - < ./packages-QoL
fi

echo -ne "\033[32;40m"
echo "Creating default xdg directories"
echo -e "\033[97;40m"

xdg-user-dirs-update

echo -ne "\033[32;40m"
echo "Cloning and deploying the dotfiles"
echo -e "\033[97;40m"

git clone "$_DOTFILES" "$_DOTFILES_DIR"
cd "$_DOTFILES_DIR"
stow -t "$HOME" .
cd ..

echo -ne "\033[32;40m"
echo "Setting up and enabling sddm"
echo -e "\033[97;40m"

sudo mkdir -p "$_SDDM_CONFIG_DIR"
sudo cp "$_SDDM_DEFAULT_CONFIG" "$_SDDM_CONFIG_DIR"
sudo sed -i "${_SDDM_CONFIG_DIR}/default.conf" -e "s/User=.*/User=${USER}/"
sudo systemctl enable sddm.service

echo -ne "\033[32;40m"
echo "Enabling multilib repository"
echo -e "\033[97;40m"

sudo sed -e 's/^#\[multilib\]$/[multilib]/' -e '\|^\[multilib\]$|{n;s|^#Include = /etc/pacman.d/mirrorlist$|Include = /etc/pacman.d/mirrorlist/|;}' -i /etc/pacman.conf
sudo pacman -Syu

echo -ne "\033[32;40m"
echo "Generating colorscheme"
echo -e "\033[97;40m"

wal --theme "$_COLORSCHEME"

echo -ne "\033[32;40m"
echo "Setting kvantum theme"
echo -e "\033[97;40m"

# the environment variable is set in hyprland config
git clone "$_KVANTUM_THEME"
cd "$_KVANTUM_THEME_NAME"
cp -r "$_KVANTUM_THEME_NAME" "$_KVANTUM_DIR"

echo -ne "\033[32;40m"
echo "Setting GTK theme"
echo -e "\033[97;40m"

git clone "$_GTK_THEME"
"./${_GTK_THEME_NAME}/${_GTK_BUILD_SCRIPT}" && "./${_GTK_THEME_NAME}/${GTK_INSTALL_SCRIPT} ${_GTK_INSTALL_FLAGS}"

echo -ne "\033[32;40m"
echo "Changing shell"
echo -e "\033[97;40m"

chsh -s /usr/bin/zsh

if [[ $_HARDWARE_SPECIFIC -eq 1 ]]; then
	echo -ne "\033[32;40m"
	echo "Setting up nvidia"
	echo -e "\033[97;40m"

	chmod +x ./nvidia.sh && ./nvidia.sh
fi
