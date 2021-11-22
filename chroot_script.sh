#!/bin/bash

echo "Set system locale, time, ..."
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
sed -i 's/#fr_FR.U/fr_FR.U/' /etc/locale.gen && locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=de-latin1" > /etc/vconsole.conf
echo "daKomputer" > /etc/hostname

password="zobidou"
echo "Set root password to $passwordshutdown"
echo -e "${password}\n$password" | passwd
password="zobidou"

echo "Enable dhcpd service"
systemctl enable dhcpcd.service

cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.ori
awk '/^HOOKS/{$5 = $5" lvm2"; print $0} /^[^H]/{print $0}' /etc/mkinitcpio.conf.ori >/etc/mkinitcpio.conf

mkinitcpio -P linux

if [ -d /sys/firmware/efi ] ; then
	grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
else
	system_disk=`lsblk | grep "disk" | cut -d" " -f1`
	grub-install --target=i386-pc /dev/$system_disk
fi

[ "lscpu | grep -ic 'intel'" != 0 ] && pacman -S intel-ucode || pacman -S amd-ucode

grub-mkconfig -o /boot/grub/grub.cfg
