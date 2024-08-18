#!/bin/bash

case "$BOARD_NAME" in
	roc-rk3328-*)
		RK_BOOT_MERGER_NAME=RK320C
		;;
	roc-rk3399-*)
		RK_BOOT_MERGER_NAME=RK330C
		;;
	*)
		
		;;
esac

cp $LBS_UBOOT_PATH/spl/u-boot-spl.bin $LBS_UBOOT_PATH/u-boot-spl-itb.bin
truncate -s 512K $LBS_UBOOT_PATH/u-boot-spl-itb.bin
cat $LBS_UBOOT_PATH/u-boot.itb >> $LBS_UBOOT_PATH/u-boot-spl-itb.bin

RK_BOOT_MERGER_INI=$(mktemp --suffix=.ini)
cat <<EOF > $RK_BOOT_MERGER_INI
[CHIP_NAME]
NAME=$RK_BOOT_MERGER_NAME
[VERSION]
MAJOR=1
MINOR=30
[CODE471_OPTION]
NUM=1
Path1=$LBS_UBOOT_PATH/tpl/u-boot-tpl.bin
Sleep=1
[CODE472_OPTION]
NUM=1
Path1=$LBS_UBOOT_PATH/u-boot-spl-itb.bin
[LOADER_OPTION]
NUM=2
LOADER1=FlashData
LOADER2=FlashBoot
FlashData=$LBS_UBOOT_PATH/tpl/u-boot-tpl.bin
FlashBoot=$LBS_UBOOT_PATH/u-boot-spl-itb.bin
[OUTPUT]
PATH=$LBS_OUT_PATH/$LBS_TARGET
EOF

$LBS_VENDOR_PATH/$VENDOR_PATH/bin/boot_merger "$RK_BOOT_MERGER_INI"
rm $RK_BOOT_MERGER_INI
