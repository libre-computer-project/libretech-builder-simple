#!/bin/bash

set -ex

cd $(readlink -f $(dirname ${BASH_SOURCE[0]}))

. config/build

LBS_downloadGCC(){
	cd "$LBS_GCC_PATH"
	if [ ! -d "gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf" ]; then
		wget https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-elf/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf.tar.xz
		tar -xf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf.tar.xz
	fi
	if [ ! -d "gcc-arm-none-eabi-7-2018-q2-update" ]; then
		wget --content-disposition https://developer.arm.com/-/media/Files/downloads/gnu-rm/7-2018q2/gcc-arm-none-eabi-7-2018-q2-update-linux.tar.bz2?revision=bc2c96c0-14b5-4bb4-9f18-bceb4050fee7?product=GNU%20Arm%20Embedded%20Toolchain,64-bit,,Linux,7-2018-q2-update
		tar -xf gcc-arm-none-eabi-7-2018-q2-update-linux.tar.bz2
	fi
	if [ ! -d "gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu" ]; then
		wget https://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
		tar -xf gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
	fi
	cd "$OLDPWD"
}
LBS_exportGCCPATH(){
	cd "$LBS_GCC_PATH"
	export PATH=$PWD/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf/bin:$PATH
	export PATH=$PWD/gcc-arm-none-eabi-7-2018-q2-update/bin:$PATH
	export PATH=$PWD/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin:$PATH
	cd "$OLDPWD"
}
LBS_getATF(){
	if [ ! -d "$LBS_ATF_PATH" ]; then
		git clone --single-branch --depth 1 -b "$ATF_GIT_BRANCH" "$ATF_GIT_URL" "$LBS_ATF_PATH"
	fi
}
LBS_buildATF(){
	CROSS_COMPILE=aarch64-elf- make -C "$LBS_ATF_PATH" distclean
	CROSS_COMPILE=aarch64-elf- make -C "$LBS_ATF_PATH" -j PLAT=$ATF_PLAT DEBUG=0 $ATF_TARGET
}
LBS_getEDK2(){
	if [ ! -d "$LBS_EDK2_PATH" ]; then
		git clone --single-branch --depth 1 -b "$EDK2_GIT_BRANCH" "$EDK2_GIT_URL" "$LBS_EDK2_PATH"
		git -C "$LBS_EDK2_PATH" submodule update --init
	fi
	if [ ! -d "$LBS_EDK2PLAT_PATH" ]; then
		git clone --single-branch --depth 1 -b "$EDK2PLAT_GIT_BRANCH" "$EDK2PLAT_GIT_URL" "$LBS_EDK2PLAT_PATH"
		git -C "$LBS_EDK2PLAT_PATH" submodule update --init
	fi
}
LBS_buildEDK2(){
	LBS_EDK2PLAT_PATH_ABS="$(readlink -f LBS_EDK2PLAT_PATH)"
	cd "$LBS_EDK2_PATH"
	export WORKSPACE="$PWD"
	export PACKAGES_PATH="$LBS_EDK2_PATH_ABS":"$PWD"
	export ACTIVE_PLATFORM="Platform/StandaloneMm/PlatformStandaloneMmPkg/PlatformStandaloneMmRpmb.dsc"
	export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
	. edksetup.sh
	make -C BaseTools clean
	make -C BaseTools
	build -p $ACTIVE_PLATFORM -b RELEASE -a AARCH64 -t GCC5 -n `nproc`
	cd "$OLDPWD"
}
LBS_getOPTEE(){
	if [ ! -d "$LBS_OPTEE_PATH" ]; then
		git clone --single-branch --depth 1 -b $OPTEE_GIT_BRANCH "$OPTEE_GIT_URL" "$LBS_OPTEE_PATH"
	fi
}
LBS_buildOPTEE(){
	:
}
LBS_getUBoot(){
	if [ ! -d "$LBS_UBOOT_PATH" ]; then
		git clone --single-branch --depth 1 -b "$UBOOT_GIT_BRANCH" "$UBOOT_GIT_URL" "$LBS_UBOOT_PATH"
	fi
}
LBS_buildUBoot(){
	BL31="$(readlink -f $LBS_ATF_PATH)"/build/$ATF_PLAT/release/$ATF_TARGET/$ATF_OUTPUT_FILE
	if [ ! -f "$BL31" ]; then
		echo "$FUNCNAME BL31 missing?"
		exit 1
	fi
	export BL31
	CROSS_COMPILE=aarch64-elf- make -C u-boot distclean
	CROSS_COMPILE=aarch64-elf- make -C u-boot -j $UBOOT_TARGET
	CROSS_COMPILE=aarch64-elf- make -C u-boot -j
}
LBS_makeSPIFlashImage(){
	if [ ! -d "$LBS_OUT_PATH" ]; then
		mkdir -p "$LBS_OUT_PATH"
	fi
	truncate -s 4M "$LBS_OUT_PATH/$LBS_TARGET"
	local loop_dev=$(sudo losetup --show -f "$LBS_OUT_PATH/$LBS_TARGET")
	sudo fdisk $loop_dev <<EOF || true
I
$SPIFLASH_SFDISK
w
EOF
	sync
	sudo partprobe $loop_dev
	if [ ! -b ${loop_dev}p1 ]; then
		echo "$FUNCNAME partition 1 is missing?"
		sudo losetup -d $loop_dev
		exit 1
	fi
	. "$SPIFLASH_LOAD"
	sudo losetup -d $loop_dev
}
if [ -z "$1" ]; then
	echo "$0 config"
	exit 1
fi

LBS_TARGET="$1"

if [ ! -f "config/$LBS_TARGET" ]; then
	echo "config $LBS_TARGET does not exist"
	exit 1
fi

. "config/$LBS_TARGET"

LBS_downloadGCC
LBS_exportGCCPATH
LBS_getATF
LBS_buildATF
#LBS_getEDK2
#LBS_buildEDK2
#LBS_getOPTEE
#LBS_buildOPTEE
LBS_getUBoot
LBS_buildUBoot
LBS_makeSPIFlashImage

