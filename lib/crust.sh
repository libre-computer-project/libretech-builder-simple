#!/bin/bash

LBS_getCrust(){
	if [ -d "$LBS_CRUST_PATH" ]; then
		LBS_GIT_switchBranch "$LBS_CRUST_PATH" "$CRUST_GIT_BRANCH"
	else
		git clone --single-branch --depth 1 -b "$CRUST_GIT_BRANCH" "$CRUST_GIT_URL" "$LBS_CRUST_PATH"
	fi
}

LBS_buildCrust(){
	CROSS_COMPILE=or1k-linux-musl- make -C "$LBS_CRUST_PATH" distclean
	CROSS_COMPILE=or1k-linux-musl- make -C "$LBS_CRUST_PATH" $CRUST_TARGET
	CROSS_COMPILE=or1k-linux-musl- make -C "$LBS_CRUST_PATH" -j$(nproc) scp
}
