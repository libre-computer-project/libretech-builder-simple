#!/bin/sh

FILE_OS_RELEASE=/etc/os-release
STRING_DISTRO_DEBIAN=debian
STRING_DISTRO_DEBIAN_BULLSEYE_ID=bullseye
STRING_DISTRO_DEBIAN_BULLSEYE_VERSION=11

FILE_NETWORK_ETH0=/etc/network/interfaces.d/eth0
STRING_NETWORK_ETH0="auto eth0\nallow-hotplug eth0\niface eth0 inet dhcp\n# iface eth0 inet6 auto\n"

FILE_FSTAB=/etc/fstab
STRING_FSTAB_GREP="\\s/\\s\\+btrfs\\s\\+"
STRING_FSTAB_SED="s/(\\s\\/\\s+btrfs\\s+)(compress=zstd,)?(noatime,)?/\\1compress=zstd,noatime,/g"

FILE_APT_SOURCES=/etc/apt/sources.list
STRING_APT_SOURCES_CDROM_SED="s/^deb\\s+cdrom.*/# \0\n\ndeb http:\\/\\/deb.debian.org\\/debian bullseye main contrib non-free/g"
STRING_APT_SOURCES_UPDATE_SED="s/^#?\\s*(deb\\s+http.*)\\s+(main)/\\1 \\2 contrib non-free/g"

FILE_GRUB=/boot/efi/EFI/BOOT/BOOTAA64.EFI
FILE_GRUB_DEFAULT=/etc/default/grub
STRING_GRUB_DEFAULT_GREP='GRUB_CMDLINE_LINUX_DEFAULT="quiet"'
STRING_GRUB_DEFAULT_SED="s/(GRUB_CMDLINE_LINUX_DEFAULT=)\"quiet\"/\\1\"noquiet\"/"
COMMAND_GRUB_INSTALL="grub-install --force-extra-removable"
COMMAND_GRUB_UPDATE="update-grub"

if [ -f "$FILE_OS_RELEASE" ]; then
	. "$FILE_OS_RELEASE"
fi
if [ ! -z "$ID" -a "$ID" = "$STRING_DISTRO_DEBIAN" ]; then
	echo -n "Debian "
	if [ ! -z "VERSION_ID" -a "$VERSION_ID" = "$STRING_DISTRO_DEBIAN_BULLSEYE_VERSION" ]; then
		echo "$STRING_DISTRO_DEBIAN_BULLSEYE_VERSION $STRING_DISTRO_DEBIAN_BULLSEYE_ID detected"
		if [ ! -f "$FILE_NETWORK_ETH0" ]; then
			if echo -e "$STRING_NETWORK_ETH0" > "$FILE_NETWORK_ETH0" > "$FILE_NETWORK_ETH0"; then
				echo "eth0 hot-plug added"
			fi
		fi
		if grep "$STRING_FSTAB_GREP" "$FILE_FSTAB" > /dev/null; then
			if sed -Ei "$STRING_FSTAB_SED" "$FILE_FSTAB"; then
				echo "btrfs zstd noatime enabled"
			fi
		fi
		if [ -f "$FILE_APT_SOURCES" ]; then
			if sed -Ei "$STRING_APT_SOURCES_CDROM_SED" "$FILE_APT_SOURCES"; then
				echo "apt cdrom repo disabled and bulleyes main enabled"
			fi
			
			if sed -Ei "$STRING_APT_SOURCES_UPDATE_SED" "$FILE_APT_SOURCES"; then
				echo "apt security and updates repo enabled"
			fi
		fi
		if grep "$STRING_GRUB_DEFAULT_GREP" "$FILE_GRUB_DEFAULT"; then
			if sed -Ei "STRING_GRUB_DEFAULT_SED" "$FILE_GRUB_DEFAULT"; then
				echo "linux quiet disabled"
			fi
		fi
		if [ ! -f "$FILE_GRUB" ]; then
			$COMMAND_GRUB_INSTALL
			$COMMAND_GRUB_UPDATE
		fi
		echo "Distro fixes applied"
	else
		echo "unsupported detected"
	fi
fi