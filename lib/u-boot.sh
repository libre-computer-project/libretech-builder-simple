#!/bin/bash

LBS_UBOOT_get(){
	if [ -d "$LBS_UBOOT_PATH" ]; then
		LBS_GIT_switchBranch "$LBS_UBOOT_PATH" "$UBOOT_GIT_BRANCH"
	else
		git clone --single-branch --depth 1 -b "$UBOOT_GIT_BRANCH" "$UBOOT_GIT_URL" "$LBS_UBOOT_PATH"
	fi
}

LBS_UBOOT_checkConfig(){
	echo $PWD
	if [ ! -z "$LBS_UBOOT_CFGCHECK" ]; then
		while read -r line; do
			grep "^$line" $1
		done < vendor/libre-computer/u-boot_configs
	fi
}

LBS_UBOOT_build(){
	if [ "$LBS_ATF" -eq 1 ]; then
		BL31="$(readlink -f $LBS_ATF_PATH)"/build/$ATF_PLAT/release/$ATF_OUTPUT_FILE
		if [ ! -f "$BL31" ]; then
			echo "$FUNCNAME BL31 missing?"
			exit 1
		fi
		export BL31
	fi
	if [ "$LBS_CRUST" -eq 1 ]; then
		SCP="$(readlink -f "$LBS_CRUST_PATH")"/build/scp/scp.bin
		if [ ! -f "$SCP" ]; then
			echo "$FUNCNAME SCP missing?"
			exit 1
		fi
		export SCP
	fi
	if [ "$LBS_OPTEE" -eq 1 ]; then
		TEE="$(readlink -f "$LBS_OPTEE_PATH")"/out/arm-plat-$OPTEE_PLATELF_DIR/core/tee.elf
		if [ ! -f "$TEE" ]; then
			echo "$FUNCNAME TEE missing?"
			exit 1
		fi
		export TEE
	fi
	CROSS_COMPILE=$LBS_CC make -C "$LBS_UBOOT_PATH" distclean
	CROSS_COMPILE=$LBS_CC make -C "$LBS_UBOOT_PATH" -j$(nproc) $UBOOT_TARGET
	if [ ! -z "$LBS_UBOOT_MENUCONFIG" ]; then
		while true; do
			CROSS_COMPILE=$LBS_CC make -C "$LBS_UBOOT_PATH" -j$(nproc) menuconfig
			read -n 1 -p "$FUNCNAME save config to defconfig? (y/N)" save
			if [ "${save,,}" = y ]; then
				CROSS_COMPILE=$LBS_CC make -C "$LBS_UBOOT_PATH" -j$(nproc) savedefconfig
				mv "$LBS_UBOOT_PATH"/defconfig "$LBS_UBOOT_PATH"/configs/$UBOOT_TARGET
			fi
			read -n 1 -p "$FUNCNAME again?" again
			if [ "${again,,}" != "y" ]; then
				break;
			fi
		done
	fi
	LBS_UBOOT_checkConfig "$LBS_UBOOT_PATH"/.config
	CROSS_COMPILE=$LBS_CC make -C "$LBS_UBOOT_PATH" -j$(nproc)
}
