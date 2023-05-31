#!/bin/bash

LBS_EDK2_get(){
	mkdir -p "$LBS_EDK2_PATH"
	if [ -d "$LBS_EDK2BASE_PATH" ]; then
		LBS_GIT_switchBranch "$LBS_EDK2BASE_PATH" "$EDK2_GIT_BRANCH"
	else
		git clone --single-branch --depth 1 -b "$EDK2_GIT_BRANCH" "$EDK2_GIT_URL" "$LBS_EDK2BASE_PATH"
	fi
	if [ -d "$LBS_EDK2PLAT_PATH" ]; then
		LBS_GIT_switchBranch "$LBS_EDK2PLAT_PATH" "$EDK2PLAT_GIT_BRANCH"
	else
		git clone --single-branch --depth 1 -b "$EDK2PLAT_GIT_BRANCH" "$EDK2PLAT_GIT_URL" "$LBS_EDK2PLAT_PATH"
	fi
	git -C "$LBS_EDK2BASE_PATH" submodule init
	git -C "$LBS_EDK2BASE_PATH" submodule update --init --recursive --single-branch --depth 1 
}

LBS_EDK2_build(){
	LBS_EDK2BASE_PATH_ABS="$(readlink -f $LBS_EDK2BASE_PATH)"
	LBS_EDK2PLAT_PATH_ABS="$(readlink -f $LBS_EDK2PLAT_PATH)"
	cd "$LBS_EDK2_PATH"
	export WORKSPACE="$PWD"
	export PACKAGES_PATH="$LBS_EDK2BASE_PATH_ABS:$LBS_EDK2PLAT_PATH_ABS"
	export ACTIVE_PLATFORM="Platform/StandaloneMm/PlatformStandaloneMmPkg/PlatformStandaloneMmRpmb.dsc"
	export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
	. "$LBS_EDK2BASE_PATH_ABS/edksetup.sh"
	make -C "$LBS_EDK2BASE_PATH_ABS/BaseTools"
	build -p $ACTIVE_PLATFORM -b RELEASE -a AARCH64 -t GCC5 -n `nproc`
	cd "$OLDPWD"
}
