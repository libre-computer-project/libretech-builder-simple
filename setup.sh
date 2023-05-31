#!/bin/bash

# Debian or Ubunutn
if which apt; then
	sudo apt install build-essential flex bison python3-setuptools swig python3-dev libssl-dev u-boot-tools python3-pyelftools git libncurses-dev
# Redhat or Fedora
elif which yum; then
	sudo yum groupinstall 'Development Tools'
	sudo yum install python3-setuptools swig python3-devel openssl-devel uboot-tools python3-pyelftools git ncurses-devel
# Gentoo Linux
elif which emerge; then
	sudo emerge -q1uDN dev-python/pyelftools dev-vcs/git dev-lang/swig sys-apps/dtc u-boot-tools
else
	echo "Warn: Package manager not supported! The OS distro you current using is not tested!"
	echo "If you still want to proceed, please install following packages, test it & report back to us:"
	echo
	echo "      build tools, python3-setuptools, python3-dev, python3-pyelftools"
	echo "      openssl-dev, u-boot-tools, swig, git"
	exit 1
fi
