#!/bin/sh

set -e

FILE_OS_RELEASE=/etc/os-release
STRING_DISTRO_DEBIAN=debian
STRING_DISTRO_DEBIAN_BULLSEYE_ID=bullseye
STRING_DISTRO_DEBIAN_BULLSEYE_VERSION=11

STRING_EMMC=mmcblk1
STRING_EMMC_BOOT0=boot0

DF_NET_add(){
	local FILE_NETWORK_ETH0=/etc/network/interfaces.d/eth0
	local STRING_NETWORK_ETH0="auto eth0\nallow-hotplug eth0\niface eth0 inet dhcp\n# iface eth0 inet6 auto\n"
	if [ ! -f "$FILE_NETWORK_ETH0" ]; then
		if echo "$STRING_NETWORK_ETH0" > "$FILE_NETWORK_ETH0"; then
			echo "eth0 hot-plug added" >&2
		else
			echo "eth0 hot-plug failed" >&2
			exit 1
		fi
	fi
}
DF_APT_fixSources(){
	local FILE_APT_SOURCES=/etc/apt/sources.list
	local STRING_APT_SOURCES_CDROM_SED="s/^deb\\s+cdrom.*/# \0\n\ndeb http:\\/\\/deb.debian.org\\/debian bullseye main contrib non-free/g"
	local STRING_APT_SOURCES_UPDATE_SED="s/^#?\\s*(deb\\s+http.*)\\s+(main)/\\1 \\2 contrib non-free/g"
	if [ -f "$FILE_APT_SOURCES" ]; then
		if sed -Ei "$STRING_APT_SOURCES_CDROM_SED" "$FILE_APT_SOURCES"; then
			echo "apt cdrom repo disabled and bullseye main enabled" >&2
		else
			echo "apt cdrom repo disabled and bullseye main failed" >&2
			exit 1
		fi
		
		if sed -Ei "$STRING_APT_SOURCES_UPDATE_SED" "$FILE_APT_SOURCES"; then
			echo "apt security and updates repo enabled" >&2
		else
			echo "apt security and updates repo failed" >&2
			exit 1
		fi
	fi
}
DF_FSTAB_addOptions(){
	local FILE_FSTAB=/etc/fstab
	local STRING_FSTAB_GREP="\\s/\\s\\+btrfs\\s\\+"
	local STRING_FSTAB_SED="s/(\\s\\/\\s+btrfs\\s+)(compress=zstd,)?(noatime,)?/\\1compress=zstd,noatime,/g"
	if grep "$STRING_FSTAB_GREP" "$FILE_FSTAB" > /dev/null; then
		if sed -Ei "$STRING_FSTAB_SED" "$FILE_FSTAB"; then
			echo "btrfs zstd noatime enabled" >&2
		else
			echo "btrfs zstd noatime failed" >&2
			exit 1
		fi
	fi
}
DF_DISK_isEMMCRoot(){
	local COMMAND_DEV_ROOT="findmnt -nvo SOURCE /"
	local dev_root=$($COMMAND_DEV_ROOT)
	dev_root="${dev_root##*/}"
	dev_root="${dev_root%%p[0-9]}"
	[ "$dev_root" = "$STRING_EMMC" ]
}
DF_DISK_convertGPTtoMBR(){
	local BLKDEV_EMMC="/dev/$1"
	local STRING_FDISK_GREP="^label: gpt\$"
	local STRING_FDISK_SED_LABEL="s/label: gpt/label: mbr/"
	local STRING_FDISK_SED_LABELID="s/label-id: .*//"
	local STRING_FDISK_SED_ESP="s/C12A7328-F81F-11D2-BA4B-00A0C93EC93B/ef/g"
	local STRING_FDISK_SED_LINUX="s/0FC63DAF-8483-4772-8E79-3D69D8477DE4/83/g"
	local STRING_FDISK_SED_SWAP="s/0657FD6D-A4AB-43C4-84E5-0933C84B4F4F/82/g"
	local STRING_FDISK_SED_PTUUID="s/, uuid=.*//g"
	local sfds=$(mktemp)
	fdisk "$BLKDEV_EMMC" > /dev/null <<EOF
O
$sfds
q
EOF
	if grep "$STRING_FDISK_GREP" "$sfds" > /dev/null; then
		sed -i "$STRING_FDISK_SED_LABEL" "$sfds" 
		sed -i "$STRING_FDISK_SED_LABELID" "$sfds" 
		sed -i "$STRING_FDISK_SED_ESP" "$sfds" 
		sed -i "$STRING_FDISK_SED_LINUX" "$sfds" 
		sed -i "$STRING_FDISK_SED_SWAP" "$sfds" 
		sed -i "$STRING_FDISK_SED_PTUUID" "$sfds"
		fdisk "$BLKDEV_EMMC" > /dev/null <<EOF
I
$sfds
w
EOF
		if [ $? -eq 0 ]; then
			echo "disk gpt2mbr completed" >&2
		else
			echo "disk gpt2mbr failed" >&2
		fi
	fi
	rm "$sfds"
}
DF_GRUB_install(){
	local FILE_GRUB=/boot/efi/EFI/BOOT/BOOTAA64.EFI
	local FILE_GRUB_DEFAULT=/etc/default/grub
	local STRING_GRUB_DEFAULT_GREP='GRUB_CMDLINE_LINUX_DEFAULT="quiet"'
	local STRING_GRUB_DEFAULT_SED="s/(GRUB_CMDLINE_LINUX_DEFAULT=)\"quiet\"/\\1\"noquiet\"/"
	local COMMAND_GRUB_INSTALL="grub-install --force-extra-removable"
	local COMMAND_GRUB_UPDATE="update-grub"
	if [ ! -f "$FILE_GRUB" ]; then
		if $COMMAND_GRUB_INSTALL; then
			echo "grub efi loader installed" >&2
		else
			echo "grub efi loader failed" >&2
			exit 1
		fi
	fi
	if grep "$STRING_GRUB_DEFAULT_GREP" "$FILE_GRUB_DEFAULT" > /dev/null; then
		if sed -Ei "$STRING_GRUB_DEFAULT_SED" "$FILE_GRUB_DEFAULT"; then
			echo "grub linux quiet disabled" >&2
		else
			echo "grub linux quiet failed" >&2
			exit 1
		fi
	fi
	
	if $COMMAND_GRUB_UPDATE 2> /dev/null; then
		echo "grub cfg updated" >&2
	else
		echo "grub cfg failed" >&2
		exit 1
	fi
}
DF_BOOT_install(){
	local FILE_BOOT_FLASH_SCRIPT=$(dirname "$0")/mbruefiloader.sh
	if [ ! -z "$2" ]; then
		local FILE_EMMC_BOOT_RO="/sys/class/block/${1}${2}/force_ro"
		echo -n 0 > "$FILE_EMMC_BOOT0_RO"
	fi
	local BLKDEV_EMMC_BOOT="${1}${2}"
	if [ -b "/dev/$BLKDEV_EMMC_BOOT" ]; then
		if "$FILE_BOOT_FLASH_SCRIPT" "$BLKDEV_EMMC_BOOT" 2> /dev/null; then
			echo "emmc bootloader installed" >&2
		else
			echo "emmc bootloader failed" >&2
			exit 1
		fi
	fi
}

if [ -f "$FILE_OS_RELEASE" ]; then
	. "$FILE_OS_RELEASE"
fi
if [ ! -z "$ID" -a "$ID" = "$STRING_DISTRO_DEBIAN" ]; then
	echo -n "Debian "
	if [ ! -z "VERSION_ID" -a "$VERSION_ID" = "$STRING_DISTRO_DEBIAN_BULLSEYE_VERSION" ]; then
		echo "$STRING_DISTRO_DEBIAN_BULLSEYE_VERSION $STRING_DISTRO_DEBIAN_BULLSEYE_ID detected"
		
		DF_NET_add
		
		DF_APT_fixSources
		
		DF_FSTAB_addOptions
		
		if DF_DISK_isEMMCRoot; then
			DF_DISK_convertGPTtoMBR "$STRING_EMMC"
			DF_BOOT_install "$STRING_EMMC"
		fi
		
		DF_GRUB_install
		
		echo "Distro fixes applied" >&2
	else
		echo "unsupported detected" >&2
		exit 1
	fi
fi