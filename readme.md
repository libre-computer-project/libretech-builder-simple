# libretech-builder-simple

This is a simple bootloader builder for Libre Computer boards.

## Usage

	sudo ./setup.sh #install pre-requisites via apt

	git clone --single-branch --depth 1 https://github.com/libre-computer-project/libretech-builder-simple.git
	./build.sh BOARD_TARGET # eg. ./build.sh roc-rk3399-pc

The default output directory is out/ and is set by LBS_OUT_PATH in configs/build.

The default board bootloader target is for MMC boot. The output bootloader needs to be written to the [correct disk sector](https://github.com/libre-computer-project/libretech-flash-tool/blob/master/lib/bootloader.sh#L5).

For boards with SPI NOR, there is a separate board bootloader target ending with -spiflash.
To flash SPI NOR, dump the output image to a MMC device and the board will boot and flash the SPI NOR.

	sudo dd if=out/BOARD_TARGET-spiflash of=/dev/null bs=1M

Replace "BOARD_TARGET" and "null" to the proper file and block device respectively. Be careful not to overwrite the wrong block device!

To configure u-boot, set LBS_UBOOT_MENUCONFIG=1.

## Boards Supported

* ALL-H3-CC-H3
* ALL-H3-CC-H5
* AML-S805X-AC
* AML-S905X-AC
* AML-S905X-CC-V2
* AML-S905D-PC
* ROC-RK3328-CC
* ROC-RK3328-CC-V2
* ROC-RK3399-PC

## More Information

### ARM Trusted Firmware
[ARM Trusted Firmware Documentation](https://trustedfirmware-a.readthedocs.io/en/latest/plat/index.html)

### U-Boot
[U-Boot Documentation](https://u-boot.readthedocs.io/en/latest/board/index.html)

### OPTEE
[StandAloneMM from EDK2 in OPTEE OS](https://optee.readthedocs.io/en/latest/building/efi_vars/stmm.html)

