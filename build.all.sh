#!/bin/bash

set -ex

cd $(readlink -f $(dirname ${BASH_SOURCE[0]}))

boards_aml=(
	aml-s805x-ac aml-s805x-ac-spi
	aml-s805x-ac-v2 aml-s805x-ac-v2-spi
	aml-s905x-cc
	aml-s905x-cc-v2 aml-s905x-cc-v2-spi
	aml-a311d-cc aml-a311d-cc-spi
	aml-a311d-cc-v01 aml-a311d-cc-v01-spi
	aml-a311d-cm-v01 aml-a311d-cm-v01-spi
	aml-s905d3-cc aml-s905d3-cc-spi
	aml-s905d3-cc-v01 aml-s905d3-cc-v01-spi
	aml-s905d3-cm aml-s905d3-cm-spi
)

boards=(all-h3-cc-h5
	roc-rk3328-cc
	roc-rk3399-pc
	${boards_aml[@]})

if [ ! -z "$1" ]; then
	case "$1" in
		amlogic)
			boards=(${boards_aml[@]})
			;;
		*)
			boards=($@)
			;;
	esac
fi

for board in ${boards[@]}; do
	./build.sh $board
done
