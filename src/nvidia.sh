#!/bin/bash
# Requires mkinitcpio and grub
set -e

MKINITCPIO_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
MODPROBE_CONFIG_DIR="/etc/modprobe.d"

# Add nvidia driver modules to the initramfs
sudo sed -e "s/^MODULES=(/MODULES=(${MKINITCPIO_MODULES}/" -i /etc/mkinitcpio.conf

sudo mkdir -p "${MODPROBE_CONFIG_DIR}"
sudo bash -c "echo -e options nvidia_drm modeset=1 fbdev=1 >> \"${MODPROBE_CONFIG_DIR}/nvidia.conf\""
sudo bash -c "echo -e options nvidia NVreg_PreserveVideoMemoryAllocations=1 >> \"${MODPROBE_CONFIG_DIR}/nvidia.conf\""

# Enable serbices needed for proper suspend
sudo systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service

# Rebuild mkinitcpio
sudo mkinitcpio -P
for time in {10..1}; do
	echo -ne "\033[2K\r\033[31;40m"
	echo -e "Warning the system will reboot in $time"
	sleep 1
done
sudo reboot
