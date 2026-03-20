#!/bin/bash

set -ex

cd $(readlink -f $(dirname ${BASH_SOURCE[0]}))

directory=
case "${1-}" in
	master)
		directory=$1
		export LBS_UBOOT_BRANCH_OVERRIDE=master
		shift
		;;
	release)
		directory=$1
		export LBS_UBOOT_BRANCH_OVERRIDE=v2026.04/master
		shift
		;;
esac

. build.all.sh "$@"

for board in ${boards[@]}; do
	./build.sh $board
	board_spiflash=
	if [ "${board%-spi}" != "$board" ]; then
		board_spiflash=out/${board%-spi}-spiflash
		if [ ! -e "$board_spiflash" ]; then
			echo "$board does not have corresponding spiflash file" >&2
			exit 1
		fi
	fi
	ssh computer-libre-boot@boot.libre.computer mkdir -p public/ci/$directory
	scp \
		out/$board \
		out/$board.config \
		out/$board.dtb \
		out/$board.dts \
		$board_spiflash \
		computer-libre-boot@boot.libre.computer:public/ci/$directory
done
