#!/bin/sh

set -ex

if [ -z "$1" ]; then
	echo "$0 TARGET #eg: $0 mmcblk1" >&2
	exit 1
fi

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOADER="$SCRIPT_DIR/u-boot.bin"
if [ ! -f "$LOADER" ]; then
	echo "MBR UEFI Bootloader file not found!" >&2
	exit 1
fi

TARGET="/dev/$1"
if [ ! -b "$TARGET" ]; then
	echo "$TARGET is not a block device!" >&2
	exit 1
fi

#TODO check starting sector of first partition

sudo dd if="$SCRIPT_DIR/u-boot.bin" of="$TARGET" conv=fsync,notrunc bs=512 seek=1