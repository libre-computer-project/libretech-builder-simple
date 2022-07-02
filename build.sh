#!/bin/bash

set -ex

cd $(readlink -f $(dirname ${BASH_SOURCE[0]}))

. configs/build

LBS_downloadGCC(){
	if [ ! -d "$LBS_GCC_PATH" ]; then
		mkdir -p "$LBS_GCC_PATH"
	fi
	cd "$LBS_GCC_PATH"
	if [ ! -d "gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf" ]; then
		wget "https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-elf/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf.tar.xz"
		tar -xf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf.tar.xz
	fi
	if [ ! -d "gcc-arm-none-eabi-7-2018-q2-update" ]; then
		wget --content-disposition "https://developer.arm.com/-/media/Files/downloads/gnu-rm/7-2018q2/gcc-arm-none-eabi-7-2018-q2-update-linux.tar.bz2?revision=bc2c96c0-14b5-4bb4-9f18-bceb4050fee7?product=GNU%20Arm%20Embedded%20Toolchain,64-bit,,Linux,7-2018-q2-update"
		tar -xf gcc-arm-none-eabi-7-2018-q2-update-linux.tar.bz2
	fi
	if [ ! -d "gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu" ]; then
		wget "https://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz"
		tar -xf gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
	fi
	if [ "$LBS_OPTEE" -eq 1 ]; then
		if [ ! -d "gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf" ]; then
			wget "https://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/arm-linux-gnueabihf/gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf.tar.xz"
			tar -xf gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf.tar.xz
		fi
	fi
	cd "$OLDPWD"
}
LBS_exportGCCPATH(){
	cd "$LBS_GCC_PATH"
	export PATH=$PWD/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf/bin:$PATH
	export PATH=$PWD/gcc-arm-none-eabi-7-2018-q2-update/bin:$PATH
	export PATH=$PWD/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin:$PATH
	if [ "$LBS_OPTEE" -eq 1 ]; then
		export PATH=$PWD/gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf/bin:$PATH
	fi
	cd "$OLDPWD"
}
LBS_GIT_switchBranch(){
	local path_tar="$1"
	local branch_tar="$2"
	local branch_cur=$(git -C "$path_tar" branch --show-current)
	if [ "$branch_cur" != "$branch_tar" ]; then
		#check for modified tracked
		local files_unc=$(git -C "$path_tar" status -s | grep -v '^??')
		if [ ! -z "$files_unc" ]; then
			echo "$FUNCNAME cannot switch branch when there are uncommited files."
			return 1
		fi
		local branch_exi=$(git -C "$path_tar" branch --list "$branch_tar")
		if [ -z "$branch_exi" ]; then
			git -C "$path_tar" fetch --depth=1 "$LBS_GIT_REMOTE_DEFAULT" "$branch_tar"
			git -C "$path_tar" checkout -b "$branch_tar" FETCH_HEAD
		else
			git -C "$path_tar" checkout "$branch_tar"
		fi
	fi
}
LBS_getATF(){
	if [ -d "$LBS_ATF_PATH" ]; then
		LBS_GIT_switchBranch "$LBS_ATF_PATH" "$ATF_GIT_BRANCH"
	else
		git clone --single-branch --depth 1 -b "$ATF_GIT_BRANCH" "$ATF_GIT_URL" "$LBS_ATF_PATH"
	fi
}
LBS_buildATF(){
	CROSS_COMPILE=aarch64-elf- make -C "$LBS_ATF_PATH" distclean
	CROSS_COMPILE=aarch64-elf- make -C "$LBS_ATF_PATH" -j PLAT=$ATF_PLAT DEBUG=0 $ATF_TARGET
}
LBS_getEDK2(){
	mkdir -p "$LBS_EDK2_PATH"
	if [ -d "$LBS_EDK2BASE_PATH" ]; then
		LBS_GIT_switchBranch "$LBS_EDK2BASE_PATH" "$EDK2_GIT_BRANCH"
	else
		git clone --single-branch --depth 1 -b "$EDK2_GIT_BRANCH" "$EDK2_GIT_URL" "$LBS_EDK2BASE_PATH"
	fi
	if [ -d "$LBS_EDK2PLAT_PATH" ]; then
		LBS_GIT_switchBranch "$LBS_EDK2PLAT_PATH" "$EDK2PLAT_GIT_BRANCH"
	else
		git clone --single-branch --depth 1 -b "$EDK2PLAT_GIT_BRANCH" "$EDK2PLAT_GIT_URL" "$LBS_EDK2PLAT_PATH"
	fi
	git -C "$LBS_EDK2BASE_PATH" submodule init
	git -C "$LBS_EDK2BASE_PATH" submodule update --init --recursive --single-branch --depth 1 
}
LBS_buildEDK2(){
	LBS_EDK2BASE_PATH_ABS="$(readlink -f $LBS_EDK2BASE_PATH)"
	LBS_EDK2PLAT_PATH_ABS="$(readlink -f $LBS_EDK2PLAT_PATH)"
	cd "$LBS_EDK2_PATH"
	export WORKSPACE="$PWD"
	export PACKAGES_PATH="$LBS_EDK2BASE_PATH_ABS:$LBS_EDK2PLAT_PATH_ABS"
	export ACTIVE_PLATFORM="Platform/StandaloneMm/PlatformStandaloneMmPkg/PlatformStandaloneMmRpmb.dsc"
	export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
	. "$LBS_EDK2BASE_PATH_ABS/edksetup.sh"
	make -C "$LBS_EDK2BASE_PATH_ABS/BaseTools"
	build -p $ACTIVE_PLATFORM -b RELEASE -a AARCH64 -t GCC5 -n `nproc`
	cd "$OLDPWD"
}
LBS_getOPTEE(){
	if [ -d "$LBS_OPTEE_PATH" ]; then
		LBS_GIT_switchBranch "$LBS_OPTEE_PATH" "$OPTEE_GIT_BRANCH"
	else
		git clone --single-branch --depth 1 -b $OPTEE_GIT_BRANCH "$OPTEE_GIT_URL" "$LBS_OPTEE_PATH"
	fi
}
LBS_buildOPTEE(){
	#ln -s "$LBS_EDK2_PATH/Build/MmStandaloneRpmb/RELEASE_GCC5/FV/BL32_AP_MM.fd" "$LBS_OPTEE_PATH" 
	ARCH=arm CROSS_COMPILE32=arm-linux-gnueabihf- make -C "$LBS_OPTEE_PATH" -j`nproc` \
		CFG_ARM64_core=y PLATFORM=$OPTEE_PLAT CFG_STMM_PATH="$PWD/$LBS_EDK2_PATH/Build/MmStandaloneRpmb/RELEASE_GCC5/FV/BL32_AP_MM.fd" \
		CFG_RPMB_FS=y CFG_RPMB_FS_DEV_ID=0 CFG_CORE_HEAP_SIZE=524288 \
		CFG_RPMB_WRITE_KEY=y CFG_CORE_HEAP_SIZE=524288 CFG_CORE_DYN_SHM=y \
		CFG_RPMB_TESTKEY=y CFG_REE_FS=n CFG_CORE_ARM64_PA_BITS=48 \
		CFG_TEE_CORE_LOG_LEVEL=3 CFG_TEE_TA_LOG_LEVEL=3 \
		CFG_SCTLR_ALIGNMENT_CHECK=n
}
LBS_getUBoot(){
	if [ -d "$LBS_UBOOT_PATH" ]; then
		LBS_GIT_switchBranch "$LBS_UBOOT_PATH" "$UBOOT_GIT_BRANCH"
	else
		git clone --single-branch --depth 1 -b "$UBOOT_GIT_BRANCH" "$UBOOT_GIT_URL" "$LBS_UBOOT_PATH"
	fi
}
LBS_buildUBoot(){
	BL31="$(readlink -f $LBS_ATF_PATH)"/build/$ATF_PLAT/release/$ATF_OUTPUT_FILE
	if [ ! -f "$BL31" ]; then
		echo "$FUNCNAME BL31 missing?"
		exit 1
	fi
	export BL31
	if [ "$LBS_OPTEE" -eq 1 ]; then
		TEE="$(readlink -f "$LBS_OPTEE_PATH")"/out/arm-plat-$OPTEE_PLATELF_DIR/core/tee.elf
		if [ ! -f "$TEE" ]; then
			echo "$FUNCNAME TEE missing?"
			exit 1
		fi
		export TEE
	fi
	CROSS_COMPILE=aarch64-elf- make -C "$LBS_UBOOT_PATH" distclean
	CROSS_COMPILE=aarch64-elf- make -C "$LBS_UBOOT_PATH" -j $UBOOT_TARGET
	if [ ! -z "$LBS_UBOOT_MENUCONFIG" ]; then
		CROSS_COMPILE=aarch64-elf- make -C "$LBS_UBOOT_PATH" -j menuconfig
		read -n 1 -p "$FUNCNAME save config to defconfig? (y/N)" save
		if [ "${save,,}" = y ]; then
			CROSS_COMPILE=aarch64-elf- make -C "$LBS_UBOOT_PATH" -j savedefconfig
			mv "$LBS_UBOOT_PATH"/defconfig "$LBS_UBOOT_PATH"/configs/$UBOOT_TARGET
		fi
	fi
	CROSS_COMPILE=aarch64-elf- make -C "$LBS_UBOOT_PATH" -j
}
LBS_finalize(){
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
	fi
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

LBS_downloadGCC
LBS_exportGCCPATH
LBS_getATF
LBS_buildATF
if [ "$LBS_OPTEE" -eq 1 ]; then
	LBS_getEDK2
	LBS_buildEDK2
	LBS_getOPTEE
	LBS_buildOPTEE
fi
LBS_getUBoot
LBS_buildUBoot
LBS_finalize
