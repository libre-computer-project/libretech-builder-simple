env set stop "while true; do sleep 1; done"
env set firmware "u-boot.bin"

if test $devtype = "usb_mass_storage"; then
	env set devtype usb
fi

env print

fdt addr $fdtcontroladdr
if fdt list /soc/bus@ffd00000/spi@14000; then
	if bind /soc/bus@ffd00000/spi@14000 meson_spifc; then
		echo "SPIFC driver bound"
	else
		echo "ERROR: SPIFC driver bind failed!"
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
