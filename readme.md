# libretech-builder-simple

## Purpose

Builds bootloaders for Libre Computer boards.

## Prerequisites

Linux machine or virtual machine

## Usage

```
#install pre-requisites via apt or yum
sudo ./setup.sh

git clone --single-branch --depth 1 https://github.com/libre-computer-project/libretech-builder-simple.git

./build.sh BOARD_TARGET

#To configure u-boot, set LBS_UBOOT_MENUCONFIG=1.
LBS_UBOOT_MENUCONFIG=1 ./build.sh BOARD_TARGET
```

## Board Targets

* all-h3-cc-h3
* all-h3-cc-h5
* aml-s805x-ac
* aml-s905x-cc
* aml-s905x-cc-v2
* aml-s905d-pc
* roc-rk3328-cc
* roc-rk3399-pc

## Bootloader Flashing

Default output directory is out/ and is set by LBS_OUT_PATH in configs/build.

Output bootloader needs to be written to the [correct disk sector](https://github.com/libre-computer-project/libretech-flash-tool/blob/master/lib/bootloader.sh#L5).

For boards with SPI NOR, there is a separate board bootloader target ending with -spiflash.
To flash SPI NOR, dump the output image to a MMC device and the board will boot and flash the SPI NOR.

`sudo dd if=out/BOARD_TARGET-spiflash of=/dev/null bs=1M`

Replace "BOARD_TARGET" and "null" to the proper file and block device respectively. **Be careful not to overwrite the wrong block device!**

## More Information

### ARM Trusted Firmware
[ARM Trusted Firmware Documentation](https://trustedfirmware-a.readthedocs.io/en/latest/plat/index.html)
[ARM Trusted Firmware Design](https://trustedfirmware-a.readthedocs.io/en/latest/design/firmware-design.html)

### U-Boot
[U-Boot Documentation](https://u-boot.readthedocs.io/en/latest/board/index.html)
[U-Boot Usage](https://u-boot.readthedocs.io/en/latest/usage/index.html)

### OPTEE
[StandAloneMM from EDK2 in OPTEE OS](https://optee.readthedocs.io/en/latest/building/efi_vars/stmm.html)

