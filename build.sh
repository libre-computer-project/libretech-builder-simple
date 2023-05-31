#!/bin/bash

set -ex

cd $(readlink -f $(dirname ${BASH_SOURCE[0]}))

. configs/build

. lib/gcc.sh
. lib/git.sh
. lib/atf.sh
. lib/crust.sh
. lib/edk2.sh
. lib/optee.sh
. lib/u-boot.sh

LBS_finalize(){
	if [ ! -d "$LBS_OUT_PATH" ]; then
		mkdir -p "$LBS_OUT_PATH"
	fi
	if [ ! -z "$AML_ENCRYPT" ]; then
		. $LBS_VENDOR_PATH/$VENDOR_PATH/encrypt.sh
		LBS_finalizeUBoot
	elif [ ! -z "$AML_GXLIMG" ]; then
		. $LBS_VENDOR_PATH/$VENDOR_PATH/gxlimg.sh
		LBS_finalizeUBoot
	fi
	if [ ! -z "$SPIFLASH" ]; then
		LBS_makeSPIFlashImage
	elif [ ! -z "$MBRUEFI" ]; then
		LBS_makeMBRUEFI
	else
		cp "$LBS_UBOOT_BIN_FINAL_PATH" "$LBS_OUT_PATH/$LBS_TARGET"
		local target_size=$(stat --printf="%s" "$LBS_OUT_PATH/$LBS_TARGET")
		case "${LBS_TARGET%%-*}" in
			all)
				local start_sector=16
				;;
			aml)
				local start_sector=1
				dd if="$LBS_UBOOT_BIN_FINAL_PATH" of="$LBS_OUT_PATH/$LBS_TARGET.usb.bl2" bs=49152 count=1
				dd if="$LBS_UBOOT_BIN_FINAL_PATH" of="$LBS_OUT_PATH/$LBS_TARGET.usb.tpl" skip=49152 bs=1
				;;
			roc)
				local start_sector=64
				;;
			*)
				echo "Unknown vendor: ${LBS_TARGET%%-*}"
				return 1
				;;
		esac
		local target_max=$((1024*1024-(start_sector*512)-0x10000))
		if [ "$target_size" -gt "$target_max" ]; then
			echo "WARNING: Target size ${target_size}B exceeds ${target_max}B"
		fi
	fi
	cp "$LBS_UBOOT_PATH"/.config "$LBS_OUT_PATH/${LBS_TARGET}.config"
	cp "$LBS_UBOOT_PATH"/u-boot.dtb "$LBS_OUT_PATH/${LBS_TARGET}.dtb"
	dtc -I dtb -O dts "$LBS_UBOOT_PATH/u-boot.dtb" -o "$LBS_OUT_PATH/${LBS_TARGET}.dts"
}
LBS_makeSPIFlashImage(){
	if [ ! -d "$LBS_OUT_PATH" ]; then
		mkdir -p "$LBS_OUT_PATH"
	fi
	truncate -s $SPIFLASH_DISK_SIZE "$LBS_OUT_PATH/$LBS_TARGET"
	local loop_dev=$(sudo losetup --show -f "$LBS_OUT_PATH/$LBS_TARGET")
	sudo fdisk $loop_dev <<EOF || true
I
$SPIFLASH_SFDISK
w
EOF
	sync
	sleep 1
	sudo partprobe $loop_dev
	if [ ! -b ${loop_dev}p1 ]; then
		read -n 1 -p "$FUNCNAME sanity check failed, partition 1 on $loop_dev is missing, drop to shell to fix? (y/N)" fix
		if [ "${fix,,}" = y ]; then
			bash
		else
			sudo losetup -d $loop_dev
			exit 1
		fi
	fi
	. "$SPIFLASH_LOAD"
	sudo losetup -d $loop_dev
}
LBS_makeMBRUEFI(){
	if [ ! -d "$LBS_OUT_PATH" ]; then
		mkdir -p "$LBS_OUT_PATH"
	fi
	truncate -s $MBRUEFI_DISK_SIZE "$LBS_OUT_PATH/$LBS_TARGET"
	local loop_dev=$(sudo losetup --show -f "$LBS_OUT_PATH/$LBS_TARGET")
	sudo fdisk $loop_dev <<EOF || true
I
$MBRUEFI_SFDISK
w
EOF
	sync
	sleep 1
	sudo partprobe $loop_dev
	if [ ! -b ${loop_dev}p1 ]; then
		read -n 1 -p "$FUNCNAME sanity check failed, partition 1 on $loop_dev is missing, drop to shell to fix? (y/N)" fix
		if [ "${fix,,}" = y ]; then
			bash
		else
			sudo losetup -d $loop_dev
			exit 1
		fi
	fi
	. "$MBRUEFI_LOAD"
	sudo losetup -d $loop_dev
}
if [ -z "$1" ]; then
	echo "$0 config"
	exit 1
fi

LBS_TARGET="$1"

if [ ! -f "configs/$LBS_TARGET" ]; then
	echo "config $LBS_TARGET does not exist"
	exit 1
fi

. "configs/$LBS_TARGET"

if [ "$HOSTTYPE" = "aarch64" ]; then
	# On AArch64 hosts, we don't download 3rd party toolchains.
	# Instead, we use the ones that come from the distribution.
	if ! command -v arm-linux-gnueabihf-gcc >/dev/null 2>&1; then
		echo "Please install a local armhf toolchain:"
		echo "  $ apt install gcc-arm-linux-gnueabihf"
		exit 1
	fi
	if [ "$LBS_CC" = "aarch64-elf-" ]; then
		# Use the system Linux cross toolchain instead, elf is not
		# always available
		LBS_CC=aarch64-linux-gnu-gcc
		if ! command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
			echo "Please install a local aarch64 toolchain:"
			echo "  $ apt install gcc"
			exit 1
		fi
	elif [ "$LBS_CC" = "arm-none-eabi-" ]; then
		if ! command -v arm-none-eabi-gcc >/dev/null 2>&1; then
			echo "Please install a local arm-none toolchain:"
			echo "  $ apt install gcc-arm-none-eabi"
			exit 1
		fi
	fi
else
	LBS_GCC_download
	LBS_GCC_exportPATH
fi
if [ "$LBS_ATF" -eq 1 ]; then
	LBS_getATF
	LBS_buildATF
fi
if [ "$LBS_CRUST" -eq 1 ]; then
	LBS_getCrust
	LBS_buildCrust
fi
if [ "$LBS_OPTEE" -eq 1 ]; then
	LBS_getEDK2
	LBS_buildEDK2
	LBS_getOPTEE
	LBS_buildOPTEE
fi
LBS_getUBoot
LBS_buildUBoot
LBS_finalize
