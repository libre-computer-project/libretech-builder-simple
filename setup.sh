#!/bin/bash

if which apt; then
	sudo apt install build-essential flex bison python3-setuptools swig python3-dev libssl-dev u-boot-tools python3-pyelftools git libncurses-dev xxd libgnutls28-dev
elif which yum; then
	sudo yum groupinstall 'Development Tools'
	sudo yum install python3-setuptools swig python3-devel openssl-devel uboot-tools python3-pyelftools git ncurses-devel
else
	echo "Package manager not supported. Please install build tools, python3-setuptools, python3-dev, python3-pyelftools, openssl-dev, u-boot-tools, swig, and git."
	exit 1
fi
