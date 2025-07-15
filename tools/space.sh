#!/bin/bash

if [ -z "$1" ]; then
	echo "$0 file" >&2
	exit 1
fi

target=$1

state=0
last=0
set -o noglob
for i in $(hexdump out/aml-a311d-cc | grep "*" -A 1 -B 1 | cut -f 1 -d " "); do
	if [ "$i" = "*" ]; then
		state=1
	elif [ $state -eq 1 ]; then
		echo "0x$last 0x$i $((0x$last >> 10))K $((0x$i - 0x$last))"
		state=0
	else
		last=$i
	fi
done
