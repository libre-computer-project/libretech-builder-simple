#!/bin/bash

LBS_GCC_download(){
	if [ ! -d "$LBS_GCC_PATH" ]; then
		mkdir -p "$LBS_GCC_PATH"
	fi
	cd "$LBS_GCC_PATH"
	if [ ! -d "gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf" ]; then
		wget "https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-elf/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf.tar.xz"
		tar -xf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf.tar.xz
	fi
	if [ ! -d "gcc-arm-none-eabi-7-2018-q2-update" ]; then
		wget --content-disposition "https://developer.arm.com/-/media/Files/downloads/gnu-rm/7-2018q2/gcc-arm-none-eabi-7-2018-q2-update-linux.tar.bz2?revision=bc2c96c0-14b5-4bb4-9f18-bceb4050fee7?product=GNU%20Arm%20Embedded%20Toolchain,64-bit,,Linux,7-2018-q2-update"
		tar -xf gcc-arm-none-eabi-7-2018-q2-update-linux.tar.bz2
	fi
	if [ ! -d "arm-gnu-toolchain-15.2.rel1-x86_64-aarch64-none-elf" ]; then
		wget --content-disposition "https://developer.arm.com/-/media/Files/downloads/gnu/15.2.rel1/binrel/arm-gnu-toolchain-15.2.rel1-x86_64-aarch64-none-elf.tar.xz"
		tar -xf arm-gnu-toolchain-15.2.rel1-x86_64-aarch64-none-elf.tar.xz
	fi
	if [ ! -d "gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu" ]; then
		wget "https://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz"
		tar -xf gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
	fi
	if [ "$LBS_CRUST" -eq 1 ]; then
		if [ ! -d "or1k-linux-musl-cross" ]; then
			wget "http://musl.cc/or1k-linux-musl-cross.tgz"
			tar -xf or1k-linux-musl-cross.tgz
		fi
	fi
	if [ "$LBS_OPTEE" -eq 1 ]; then
		if [ ! -d "gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf" ]; then
			wget "https://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/arm-linux-gnueabihf/gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf.tar.xz"
			tar -xf gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf.tar.xz
		fi
	fi
	cd "$OLDPWD"
}

LBS_GCC_exportPATH(){
	cd "$LBS_GCC_PATH"
	if [ "$LBS_ARCH" = "arm64" ]; then
		export PATH=$PWD/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf/bin:$PATH
		export PATH=$PWD/arm-gnu-toolchain-15.2.rel1-x86_64-aarch64-none-elf/bin:$PATH
		export PATH=$PWD/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin:$PATH
	fi
	export PATH=$PWD/gcc-arm-none-eabi-7-2018-q2-update/bin:$PATH
	if [ "$LBS_CRUST" -eq 1 ]; then
		export PATH=$PWD/or1k-linux-musl-cross/bin:$PATH
	fi
	if [ "$LBS_OPTEE" -eq 1 ]; then
		export PATH=$PWD/gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf/bin:$PATH
	fi
	cd "$OLDPWD"
}
