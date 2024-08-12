#!/bin/bash
# Requires mkinitcpio and grub
set -e

MKINITCPIO_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
MKINITCPIO_CONFIG="/etc/mkinitcpio.conf"
MODPROBE_CONFIG_DIR="/etc/modprobe.d"
MODPROBE_CONFIG_NVIDIA="${MODPROBE_CONFIG_DIR}/nvidia.conf"

echo -ne "\033[31;40m"
echo "WARNING: This script doesn't install the kernel headers for you. If you get 'module not found:' errors that may be why. Please install the apropriate kernel headers for your kernel. You can add the right kernel header package to the packages-bare-bones file"
echo "Press enter to continue..."
echo -e "\033[97;40m"
read -s

set +e
# Add nvidia driver modules to the initramfs
modules_found=`grep "${MKINITCPIO_MODULES}" "${MKINITCPIO_CONFIG}"`
set -e

if [[ -z $modules_found ]]; then
	sudo sed -e "s/^MODULES=(/MODULES=(${MKINITCPIO_MODULES}/" -i "${MKINITCPIO_CONFIG}"
fi

if [[ -f "${MODPROBE_CONFIG_NVIDIA}" ]]; then
	echo "${MODPROBE_CONFIG_NVIDIA}, already exists"
	exit 1
else
	sudo mkdir -p "${MODPROBE_CONFIG_DIR}"
	sudo bash -c "cat > ${MODPROBE_CONFIG_NVIDIA} << EOF
options nvidia_drm modeset=1 fbdev=1 
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF"
fi

# Enable serbices needed for proper suspend
sudo systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service

# Rebuild initramfs
sudo mkinitcpio -P
echo -ne "\033[2K\r\033[31;40m"
echo -e "Because of setting kernel parameters, and some other stuff a reboot is required for everything to work properly"
echo -e "\033[2K\r\033[97;40m"

