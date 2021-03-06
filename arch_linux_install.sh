#!/bin/zsh

loadkeys fr-latin1

timedatectl set-ntp true

storage_disk=`lsblk | grep 'disk' | cut -d" " -f1`

echo -e "\t$storage_disk"

if [ -d /sys/firmware/efi/efivars ] ; then
	echo "System booted on efi"
	partition_table="./efi.sfdisk"	
	
	efi_part="${storage_disk}1"
	swap_part="${storage_disk}2"
	root_part="${storage_disk}3"

else
	echo "System booted on BIOS"
	partition_table="./mbr.sfdisk"
	
	swap_part="${storage_disk}1"
	root_part="${storage_disk}2"
fi

sleep1

echo "Partitionning of the system disk"
sfdisk "/dev/$storage_disk" <<< `$partition_table "$storage_disk"`

sleep1

echo "Configure root_partition with LVM"
pvcreate $root_part
vg_name="volgLinux"
vgcreate $vg_name $root_part
lv_root="lvroot"
lv_home="lvhome"
lvcreate -l 90%FREE $vg_name -n $lv_root
lvcreate -l 100%FREE $vg_name -n $lv_home
lsblk

echo "Format & mount SWAP"
mkswap "/dev/$swap_part"
swapon "/dev/$swap_part"

echo "Format & mount root partition"
mkfs.ext4 "/dev/${vg_name}/$lv_root"
mount "/dev/${vg_name}/$lv_root" /mnt

echo "Format & mount home partition"
mkfs.ext4 "/dev/${vg_name}/$lv_home"
mkdir /mnt/home
mount "/dev/${vg_name}/$lv_home" /mnt/home

if [ -d /sys/firmware/efi/efivars ] ; then
	echo "Format & mount efi partition"
	mkfs.fat -F 32 "/dev/$efi_part"
	mkdir /mnt/boot
	mount "/dev/$efi_part" /mnt/boot
fi

sleep 1

echo "Downloading Arch-Linux packages and base commands"
pacstrap /mnt base linux linux-firmware vim man-db man-pages texinfo dhcpcd iproute2 grub efibootmgr lvm2

sleep 1

echo "Generate fstab"
genfstab -U /mnt > /mnt/etc/fstab

sleep 1

echo "Chrooting into Arch-Linux installation using a script"
cp ./chroot_script.sh /mnt/root/script.sh
arch-chroot /mnt `/bin/bash ~/script.sh`
rm /mnt/root/script.sh

#reboot
