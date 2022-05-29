# libretech-builder-simple

This is a simple builder for Libre Computer boards.

## Usage

	git clone --single-branch https://github.com/libre-computer-project/libretech-builder-simple.git
	./build.sh BOARD_TARGET # eg. ./build.sh roc-rk3399-pc
	
out/BOARD_TARGET is an image that will update the SPI NOR of the board if you write it to a card.

	sudo dd if=out/BOARD_TARGET of=/dev/null bs=1M

Replace "BOARD_TARGET" and "null" to the proper file and block device respectively. Be careful!

## More Information

For a better understanding, please see [u-boot v2022.04 for ROC-RK3399-PC](https://docs.google.com/document/d/1AAM7x48Z95iLpF5f5JBrEqgYNY27Idx1-nfyYzHDvZw/edit?usp=sharing).