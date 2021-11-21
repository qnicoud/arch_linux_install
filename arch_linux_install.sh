#!/bin/zsh

loadkeys fr-latin1

timedatectl set-ntp true

storage_disk=`lsblk | grep 'disk' | cut -d" " -f1`

echo -e "${bc}${Gc}${Bf}"
echo -e "\t$storage_disk"

if [ -d /sys/firmware/efi/efivars ] ; then
	echo "System booted on efi"
	partition_table="./efi.sfdisk"	
	
	efi_part="${storage_disk}1"
	swap_part="${storage_disk}2"
	root_part="${storage_disk}3"

	mkfs.fat -F 32 "/dev/$efi_part"	
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

echo "Format partitions"
mkswap "/dev/$swap_part"
mkfs.ext4 "/dev/$root_part"

sleep 1

echo "Mounting partitions"
mount "/dev/$root_part" /mnt
swapon "/dev/$swap_part"

sleep 1

echo "Downloading Arch-Linux packages and base commands"
pacstrap /mnt base linux linux-firmware vim man-db man-pages texinfo dhcpcd iproute2 grub

sleep 1

echo "Generate fstab"
genfstab -U /mnt >> /mnt/etc/fstab

sleep 1

echo "Chrooting into Arch-Linux installation using a script"
cp ./chroot_script.sh /mnt/root/
arch-chroot /mnt `./chroot_script.sh`

reboot
