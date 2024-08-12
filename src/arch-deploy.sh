#!/bin/bash
set -e

_HELP_MSG="This is a simple arch deplyoment script. It's meant to be run after a fresh install of arch.
By default bare bones setup will be perfomed without setting up any sort of hardware specific software and QoL software.
--hardware-specific\tWill install and setup nvidia drivers and additional firmware to get sound working on some computers\n
--qol\t\t\tWill install some quality of life software\n
--help\t\t\tDisplays this message"
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
_GTK_THEME_DIR="Tokyonight-GTK-Theme-new-colors/themes"
_GTK_INSTALL_SCRIPT="install.sh"
_GTK_BUILD_SCRIPT="build.sh"
_GTK_TWEAKS="macos"
_WALLPAPER_TARGET="${HOME}/wallpapers/tokyo-night/street-tn.png"
_WALLPAPER_LINK_NAME="${HOME}/.currentwal.png"

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

color_decorations () {
	echo -ne "\033[32;40m"
	echo $1
	echo -e "\033[97;40m"
}

install_yay () {
	color_decorations "Installing yay"
	
	sudo pacman -S --noconfirm --needed base-devel go
	git clone https://aur.archlinux.org/yay.git
	cd yay
	makepkg
	package=`ls -1 | grep -E 'yay.*zst' | grep -v debug`
	sudo pacman -U --noconfirm "$package"
	cd ../
}

install_packages () {
	color_decorations "Installing chosen packages"

	sudo pacman -S --needed --noconfirm - < ./packages-depconflict 
	cat ./packages-bare-bones >> ./packages
	cat ./packages-bare-bones-aur >> ./pakcages-aur

	if [[ $_HARDWARE_SPEC -eq 1 ]]; then
		cat ./packages-hardware-specific >> ./packages
	fi

	if [[ $_QOL -eq 1 ]]; then
		cat ./packages-QoL >> ./packages
		cat ./packages-QoL-aur >> ./packages-aur
	fi
	sudo pacman -S --needed --noconfirm - < ./packages
	yay -S --needed --noconfirm - < ./packages-aur
}

create_xdg_dirs () {
	color_decorations "Creating default xdg directories"

	xdg-user-dirs-update
}

deploy_dotfiles () {
	color_decorations "Cloning and deploying the dotfiles"

	git clone "$_DOTFILES" "$_DOTFILES_DIR"
	cd "$_DOTFILES_DIR"
	stow -t "$HOME" .
	cd ..
}

sddm_stuff () {
	color_decorations "Setting up and enabling sddm"

	sudo mkdir -p "$_SDDM_CONFIG_DIR"
	sudo cp "$_SDDM_DEFAULT_CONFIG" "$_SDDM_CONFIG_DIR"
	sudo sed -i "${_SDDM_CONFIG_DIR}/default.conf" -e "s/User=.*/User=${USER}/"
	sudo systemctl enable sddm.service
}

enable_multilib_repo () {
	color_decorations "Enabling multilib repository"

	sudo sed -e 's/^#\[multilib\]$/[multilib]/' -e '\|^\[multilib\]$|{n;s|^#Include = /etc/pacman.d/mirrorlist$|Include = /etc/pacman.d/mirrorlist/|;}' -i /etc/pacman.conf
	sudo pacman -Syu
}

generate_colorscheme () {
	color_decorations "Generating colorscheme"

	wal --theme "$_COLORSCHEME"
}

set_kvantum_theme () {
	color_decorations "Setting kvantum theme"

	# the environment variable is set in hyprland config
	git clone "$_KVANTUM_THEME"
	cd "$_KVANTUM_THEME_NAME"
	cp -r "$_KVANTUM_THEME_NAME" "$_KVANTUM_DIR"
	cd ..
}

set_gtk_theme () {
	color_decorations "Setting GTK theme"

	git clone "$_GTK_THEME"
	cd "$_GTK_THEME_DIR"
	"./${_GTK_BUILD_SCRIPT}" && "./${_GTK_INSTALL_SCRIPT}" --tweaks "${_GTK_TWEAKS}"
}

change_shell () {
	color_decorations "Changing shell to zsh"

	chsh -s /usr/bin/zsh
}

symlink_first_wallpaper () {
	color_decorations "Symlinking an initial wallpaper"

	ln -s "$_WALLPAPER_TARGET" "$_WALLPAPER_LINK_NAME"
}

run_nvidia () {
	color_decorations "Setting up nvidia"
	
	chmod +x ./nvidia.sh && ./nvidia.sh
}

if [[ -z "$(pacman -Qs yay)" ]]; then
	install_yay
fi

install_packages

create_xdg_dirs

deploy_dotfiles

sddm_stuff

enable_multilib_repo

generate_colorscheme

set_kvantum_theme

set_gtk_theme

change_shell

symlink_first_wallpaper

if [[ $_HARDWARE_SPEC -eq 1 ]]; then
	run_nvidia
fi

color_decorations "Finished! You can reboot now."
