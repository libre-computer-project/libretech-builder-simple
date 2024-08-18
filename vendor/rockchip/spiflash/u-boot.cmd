env set stop "while true; do sleep 1; done"
env set firmware "u-boot-rockchip-spi.bin"
env set spi_flash_overlay "%SPI_FLASH_OVERLAY%"
env set spi_of_node "%SPI_OF_NODE%"
env set spi_driver "%SPI_DRIVER%"

if test $devtype = "usb_mass_storage"; then
	env set devtype usb
fi

env print

fdt addr $fdtcontroladdr
if fdt list $spi_of_node; then
	if load $devtype $devnum $kernel_addr_r $spi_flash_overlay; then
		fdt apply $kernel_addr_r
		echo "SPI FLASH overlay applied"
	else
		echo "ERROR: SPI FLASH overlay failed!"
		run stop
		exit
	fi
	if bind $spi_of_node $spi_driver; then
		echo "SPI driver bound"
	else
		echo "ERROR: SPI driver bind failed!"
		run stop
		exit
	fi
fi

if sf probe; then
	echo "SPI NOR found"
else
	echo "ERROR: SPI NOR not found!"
	run stop
	exit
fi

if load $devtype $devnum $ramdisk_addr_r ${firmware}.sha1sum; then
	echo "Firmware checksum loaded"
else
	echo "ERROR: Firmware checksum load failed!"
	run stop
	exit
fi

if load $devtype $devnum $kernel_addr_r $firmware; then
	echo "Firmware loaded"
else
	echo "ERROR: Firmware load failed!"
	run stop
	exit
fi

if hash -v sha1 $kernel_addr_r $filesize *$ramdisk_addr_r; then
	echo "Checksum verified"
else
	hash sha1 $kernel_addr_r $filesize *$kernel_addr_r
	if cmp.l $kernel_addr_r $ramdisk_addr_r 5; then
		echo "Checksum verified"
	else
		echo "ERROR: Checksum failed!"
		run stop
		exit
	fi
fi

if sf update $kernel_addr_r 0 $filesize; then
	echo "Firmware updated"
else
	echo "ERROR: Firmware update failed!"
	run stop
	exit
fi

if sf read $kernel_addr_r 0 $filesize; then
	echo "Firmware read"
else
	echo "ERROR: Firmware read failed!"
	run stop
	exit
fi

if hash -v sha1 $kernel_addr_r $filesize *$ramdisk_addr_r; then
	echo "Firmware checksum match"
else
	hash sha1 $kernel_addr_r $filesize *$kernel_addr_r
	if cmp.l $kernel_addr_r $ramdisk_addr_r 5; then
		echo "Checksum verified"
	else
		echo "ERROR: Firmware checksum do not match!"
		run stop
		exit
	fi
fi

echo Flash Completed
run stop
poweroff
