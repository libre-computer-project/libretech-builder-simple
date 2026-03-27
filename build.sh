#!/bin/bash

cd $(readlink -f $(dirname ${BASH_SOURCE[0]}))

. configs/build

# Lock the output directory to prevent concurrent builds from corrupting it
_LOCKFILE="${LBS_OUT_PATH:=out}/.build.lock"
mkdir -p "$LBS_OUT_PATH"
exec 9>"$_LOCKFILE"
if ! flock -n 9; then
	echo ":: Waiting for concurrent U-Boot build to finish..."
	flock -w 600 9 || { echo "ERROR: Timed out waiting for U-Boot build lock"; exit 1; }
fi

. lib/gcc.sh
. lib/git.sh
. lib/atf.sh
. lib/crust.sh
. lib/edk2.sh
. lib/optee.sh
. lib/u-boot.sh
. lib/overlays.sh

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
	if [ ! -z "$LBS_NFS" ]; then
		. lib/nfs.sh
		LBS_NFS_build
	elif [ ! -z "$LBS_MBRUEFI" ]; then
		. lib/mbruefi.sh
		LBS_MBRUEFI_build
	elif [ ! -z "$LBS_BR2" ]; then
		. lib/br2.sh
		LBS_BR2_build
	elif [ ! -z "$LBS_UMS_EMMC" ]; then
		. lib/ums-emmc.sh
		LBS_UMS_EMMC_build
	else
		cp "$LBS_UBOOT_BIN_FINAL_PATH" "$LBS_OUT_PATH/$LBS_TARGET"
		if [ -z "$LBS_TARGET_OVERRIDE" ]; then
			local target_size=$(stat --printf="%s" "$LBS_OUT_PATH/$LBS_TARGET")
			case "${LBS_TARGET%%-*}" in
				all)
					:
					;;
				aml)
					if [ -z "$AML_ENCRYPT" ]; then
						dd if="$LBS_OUT_PATH/$LBS_TARGET" of="$LBS_OUT_PATH/$LBS_TARGET.usb.bl2" bs=49152 count=1
						dd if="$LBS_OUT_PATH/$LBS_TARGET" of="$LBS_OUT_PATH/$LBS_TARGET.usb.tpl" skip=49152 bs=1
					fi
					;;
				roc)
					:
					;;
				*)
					echo "$FUNCNAME: unknown vendor: ${LBS_TARGET%%-*}" >&2
					return 1
					;;
			esac
			if [ "${LBS_TARGET%-spi}" = "${LBS_TARGET}" ]; then
				local target_max=$((1024*1024-(LBS_BOOT_SECTOR*512)))
				if [ "$target_size" -gt "$target_max" ]; then
					echo "$FUNCNAME: WARNING: Target size ${target_size}B exceeds ${target_max}B" >&2
					echo "$FUNCNAME: Continue? (y/n)" >&2
					read -n 1 target_max_continue
					if [ "${target_max_continue,,}" != "y" ]; then
						false
					fi
				fi
			fi
		fi
	fi
	LBS_OVERLAYS_build_fit
	if [ ! -z "$LBS_SPIFLASH" ]; then
		. lib/spiflash.sh
		LBS_SPIFLASH_build
	fi
	cp "$LBS_UBOOT_PATH"/.config "$LBS_OUT_PATH/${LBS_TARGET}.config"
	cp "$LBS_UBOOT_PATH"/u-boot.dtb "$LBS_OUT_PATH/${LBS_TARGET}.dtb"
	dtc -I dtb -O dts "$LBS_UBOOT_PATH/u-boot.dtb" -o "$LBS_OUT_PATH/${LBS_TARGET}.dts"
}
if [ -z "$1" ] || [ "$1" = "list" ]; then
	if [ "$1" = "list" ]; then
		for cfg in configs/*; do
			cfg_name=$(basename "$cfg")
			result=$(bash -c ". configs/build; . \"$cfg\" 2>/dev/null; [ ! -z \"\$UBOOT_TARGET\" ] && echo \"\$UBOOT_BRANCH\"")
			if [ ! -z "$result" ]; then
				printf "%-40s %s\n" "$cfg_name" "$result"
			fi
		done
		exit 0
	fi
	echo "Usage: $0 <board-target>"
	echo "       $0 list"
	exit 1
fi

LBS_TARGET="$1"

if [ ! -f "configs/$LBS_TARGET" ]; then
	echo "config $LBS_TARGET does not exist"
	exit 1
fi

. "configs/$LBS_TARGET"

if [ -z "$UBOOT_TARGET" ]; then
	echo "$LBS_TARGET is not a valid target config!" >&2
	exit 1
fi

if [ ! -z "$LBS_TARGET_OVERRIDE" ]; then
	LBS_TARGET=$LBS_TARGET_OVERRIDE
fi

if [ ! -z "$LBS_UBOOT_BRANCH_OVERRIDE" ]; then
	UBOOT_BRANCH=$LBS_UBOOT_BRANCH_OVERRIDE
fi

if [ -z "$LBS_CC" ]; then
	case "$LBS_ARCH" in
		arm64) LBS_CC=aarch64-none-elf-;;
		armhf) LBS_CC=arm-none-eabi-;;
		*) echo "Unknown LBS_ARCH: $LBS_ARCH" >&2; exit 1;;
	esac
fi

set -ex

if [ "$HOSTTYPE" = "aarch64" ]; then
	# On AArch64 hosts, use distribution toolchains instead of
	# downloading 3rd party x86_64 binaries.
	if [ "$LBS_CC" = "aarch64-elf-" ] || [ "$LBS_CC" = "aarch64-none-elf-" ]; then
		LBS_CC=aarch64-linux-gnu-
		if ! command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
			echo "Please install a local aarch64 toolchain:"
			echo "  $ apt install gcc-aarch64-linux-gnu"
			exit 1
		fi
	elif [ "$LBS_CC" = "arm-none-eabi-" ]; then
		if ! command -v arm-none-eabi-gcc >/dev/null 2>&1; then
			echo "Please install a local arm-none toolchain:"
			echo "  $ apt install gcc-arm-none-eabi"
			exit 1
		fi
	fi
	if ! command -v arm-linux-gnueabihf-gcc >/dev/null 2>&1; then
		echo "Please install a local armhf toolchain:"
		echo "  $ apt install gcc-arm-linux-gnueabihf"
		exit 1
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
