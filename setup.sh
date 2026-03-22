#!/bin/bash

if which apt >/dev/null 2>&1; then
	sudo apt install build-essential flex bison python3-setuptools swig python3-dev libssl-dev u-boot-tools python3-pyelftools git libncurses-dev xxd libgnutls28-dev efitools genimage
	if [ "$(uname -m)" = "aarch64" ]; then
		# On AArch64 hosts, use distribution cross-compilers
		sudo apt install gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf gcc-arm-none-eabi gcc-or1k-elf
	fi
elif which yum >/dev/null 2>&1; then
	sudo yum groupinstall 'Development Tools'
	sudo yum install python3-setuptools swig python3-devel openssl-devel uboot-tools python3-pyelftools git ncurses-devel
else
	echo "Package manager not supported. Please install build tools, python3-setuptools, python3-dev, python3-pyelftools, openssl-dev, u-boot-tools, swig, and git."
	exit 1
fi
