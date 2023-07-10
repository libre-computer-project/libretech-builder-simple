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
. lib/buildroot.sh

LBS_finalize(){
	if [ ! -d "$LBS_OUT_PATH" ]; then
		mkdir -p "$LBS_OUT_PATH"
	fi
	if [ ! -z "$AML_ENCRYPT" ]; then
		. $LBS_VENDOR_PATH/$VENDOR_PATH/encrypt.sh
		LBS_VENDOR_finalize
	elif [ ! -z "$AML_GXLIMG" ]; then
		. $LBS_VENDOR_PATH/$VENDOR_PATH/gxlimg.sh
		LBS_VENDOR_finalize
	fi
	if [ ! -z "$LBS_SPIFLASH" ]; then
		. lib/spiflash.sh
		LBS_SPIFLASH_build
	elif [ ! -z "$LBS_MBRUEFI" ]; then
		. lib/mbruefi.sh
		LBS_MBRUEFI_build
	elif [ ! -z "$LBS_BR2" ]; then
		LBS_BR2_build
	else
		cp "$LBS_UBOOT_BIN_FINAL_PATH" "$LBS_OUT_PATH/$LBS_TARGET"
		local target_size=$(stat --printf="%s" "$LBS_OUT_PATH/$LBS_TARGET")
		case "${LBS_TARGET%%-*}" in
			all)
				:
				;;
			aml)
				:
				;;
			roc)
				:
				;;
			*)
				echo "$FUNCNAME: unknown vendor: ${LBS_TARGET%%-*}" >&2
				return 1
				;;
		esac
		local target_max=$((1024*1024-(LBS_BOOT_SECTOR*512)-0x10000))
		if [ "$target_size" -gt "$target_max" ]; then
			echo "$FUNCNAME: WARNING: Target size ${target_size}B exceeds ${target_max}B" >&2
		fi
	fi
	cp "$LBS_UBOOT_PATH"/.config "$LBS_OUT_PATH/${LBS_TARGET}.config"
	cp "$LBS_UBOOT_PATH"/u-boot.dtb "$LBS_OUT_PATH/${LBS_TARGET}.dtb"
	dtc -I dtb -O dts "$LBS_UBOOT_PATH/u-boot.dtb" -o "$LBS_OUT_PATH/${LBS_TARGET}.dts"
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
if [ ! -z "$LBS_ATF" ] && [ "$LBS_ATF" -eq 1 ]; then
	LBS_ATF_get
	LBS_ATF_build
fi
if [ ! -z "$LBS_CRUST" ] && [ "$LBS_CRUST" -eq 1 ]; then
	LBS_CRUST_get
	LBS_CRUST_build
fi
if [ ! -z "$LBS_OPTEE" ] && [ "$LBS_OPTEE" -eq 1 ]; then
	LBS_EDK2_get
	LBS_EDK2_build
	LBS_OPTEE_get
	LBS_OPTEE_build
fi
LBS_UBOOT_get
LBS_UBOOT_build
if [ ! -z "$LBS_BR2" ] && [ "$LBS_BR2" -eq 1 ]; then
	LBS_BR2_get
fi
LBS_finalize
