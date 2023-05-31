#!/bin/bash

LBS_SPIFLASH_build(){
	if [ ! -d "$LBS_OUT_PATH" ]; then
		mkdir -p "$LBS_OUT_PATH"
	fi
	truncate -s $LBS_SPIFLASH_DISK_SIZE "$LBS_OUT_PATH/$LBS_TARGET"
	local loop_dev=$(sudo losetup --show -f "$LBS_OUT_PATH/$LBS_TARGET")
	sudo fdisk $loop_dev <<EOF || true
I
$LBS_SPIFLASH_SFDISK
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
	. "$LBS_SPIFLASH_LOAD"
	sudo losetup -d $loop_dev
}
