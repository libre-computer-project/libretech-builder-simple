#!/bin/bash

LBS_ATF_get(){
	if [ -d "$LBS_ATF_PATH" ]; then
		LBS_GIT_switchBranch "$LBS_ATF_PATH" "$ATF_GIT_BRANCH"
	else
		git clone --single-branch --depth 1 -b "$ATF_GIT_BRANCH" "$ATF_GIT_URL" "$LBS_ATF_PATH"
	fi
}

LBS_ATF_build(){
	CROSS_COMPILE=$LBS_CC make -C "$LBS_ATF_PATH" distclean
	CROSS_COMPILE=$LBS_CC make -C "$LBS_ATF_PATH" -j$(nproc) PLAT=$ATF_PLAT DEBUG=0 $ATF_TARGET
}
