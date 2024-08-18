#!/bin/bash

LBS_UMS_EMMC_build(){
	if [ ! -d "$LBS_OUT_PATH" ]; then
		mkdir -p "$LBS_OUT_PATH"
	fi
	. "$LBS_UMS_EMMC_LOAD"
}
