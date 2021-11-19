 #!/bin/zsh

 loadkeys fr-latin1

 timedatectl set-ntp true

 storage_disk=`lsblk | grep 'disk' | cut -d" " -f1`

 if [ -d /sys/firmware/efi/efivars ] ; then
	partition_table="./efi.sfdisk"	
	
	efi_part="${storage_disk}1"
	swap_part="${storage_disk}2"
	root_part="${storage_disk}3"

	mkfs.fat -F 32 "/dev/$efi_part"	
 else
	partition_table="./mbr.sfdisk"
	
	swap_part="${storage_disk}1"
	root_part="${storage_disk}2"
 fi

sfdisk "/dev/$storage_disk" < $partition_table

mkswap "/dev/$swap_part"
mkfs.ext4 "/dev/$root_part"

mount "/dev/$root_part" /mnt
swapon "/dev/$swap_part"

pacstrap /mnt base linux linux-firmware vim man-db man-pages texinfo dhcpcd iproute2

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt ./chroot_script.sh

reboot
