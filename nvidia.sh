#!/bin/bash
# Requires mkinitcpio and grub

MKINITCPIO_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
MODPROBE_CONFIG_DIR="/etc/modprobe.d"

# Add nvidia driver modules to the initramfs
sudo sed -e "s/^MODULES=(/MODULES(${MKINITCPIO_MODULES}/" /etc/mkinitcpio.conf

sudo mkdir -p "${MODPROBE_CONFIG_DIR}"
echo -e "options nvidia_drm modeset=1 fbdev=1\n
		options nvidia NVreg_PreserveVideoMemoryAllocations=1" >> "${MODPROBE_CONFIG_DIR}/nvidia.conf"

# Enable serbices needed for proper suspend
sudo systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service

# Rebuild mkinitcpio
sudo mkinitcpio -P
for time in {10..1}; do
	echo -ne "\033[2K\r"
	echo -e "Warning the system will reboot in $time"
	sleep 1
done
sudo reboot
