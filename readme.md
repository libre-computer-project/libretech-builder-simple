# libretech-builder-simple

This is a simple builder for Libre Computer boards.

## Usage

	git clone --single-branch --depth 1 https://github.com/libre-computer-project/libretech-builder-simple.git
	./build.sh BOARD_TARGET # eg. ./build.sh roc-rk3399-pc
	
out/BOARD_TARGET is an image that will update the SPI NOR of the board if you write it to a MicroSD card.

	sudo dd if=out/BOARD_TARGET of=/dev/null bs=1M

Replace "BOARD_TARGET" and "null" to the proper file and block device respectively. Be careful!

## More Information

### Builder
[u-boot v2022.04 for ROC-RK3399-PC](https://docs.google.com/document/d/1AAM7x48Z95iLpF5f5JBrEqgYNY27Idx1-nfyYzHDvZw/edit?usp=sharing).

### ARM Trusted Firmware
[Trusted Firmware for Rockchip SoCs](https://trustedfirmware-a.readthedocs.io/en/latest/plat/rockchip.html?highlight=rockchip#rockchip-socs)

### OPTEE
[StandAloneMM from EDK2 in OPTEE OS](https://optee.readthedocs.io/en/latest/building/efi_vars/stmm.html)

### U-Boot
[Building and Flashing U-Boot for Rockchip SoCs](https://u-boot.readthedocs.io/en/latest/board/rockchip/rockchip.html?highlight=rockchip#building)
