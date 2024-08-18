#!/bin/bash

LBS_BR2_OUTPUT_PATH="$LBS_BR2_PATH/output/images"

LBS_BR2_get(){
	if [ -d "$LBS_BR2_PATH" ]; then
		LBS_GIT_switchBranch "$LBS_BR2_PATH" "$BR2_GIT_BRANCH"
	else
		git clone --single-branch --depth 1 -b "$BR2_GIT_BRANCH" "$BR2_GIT_URL" "$LBS_BR2_PATH"
	fi
}

LBS_BR2_build(){
	#make -C "$LBS_BR2_PATH" clean
	make -C "$LBS_BR2_PATH" $BR2_TARGET
	mkdir -p "$LBS_BR2_OUTPUT_PATH"
	cp "$LBS_UBOOT_BIN_FINAL_PATH" "$LBS_BR2_OUTPUT_PATH/u-boot.bin"
	make -C "$LBS_BR2_PATH"
	cp "$LBS_BR2_OUTPUT_PATH/sdcard.img" "$LBS_OUT_PATH/$LBS_TARGET"
}
