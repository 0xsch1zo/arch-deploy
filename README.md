<h1>Arch deploy script</h1>

This script is supposed to be used after a fresh install of arch. It installs my [dotfiles](https://github.com/sentientbottleofwine/dotfiles), sets up sound, installs themes and more.

> [!WARNING]
> This script has been tested but still use it at your own risk

## Usage
```
This is a simple arch deplyoment script. It's meant to be run after a fresh install of arch.
By default bare bones setup will be perfomed without setting up any sort of hardware specific software and QoL software.
--hardware-specific	Will install and setup nvidia drivers and additional firmware to get sound working on some computers

--qol			Will install some quality of life software

--help			Displays this message
```

## Install
All of packages-* files are package lists.
```sh
git clone https://github.com/sentientbottleofwine/arch-deploy
cd arch-deploy/src/
./arch-deploy.sh [options]
```
