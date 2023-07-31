env set stop "while true; do sleep 1; done"

if test $devtype = "usb_mass_storage"; then
	env set devtype usb
fi

if sf probe; then
	echo "SPI NOR found"
else
	echo "ERROR: SPI NOR not found!"
	run stop
	exit
fi

if load $devtype $devnum $ramdisk_addr_r u-boot.bin.sha1sum; then
	echo "Firmware checksum loaded"
else
	echo "ERROR: Firmware checksum load failed!"
	run stop
	exit
fi

if load $devtype $devnum $kernel_addr_r u-boot.bin; then
	echo "Firmware loaded"
else
	echo "ERROR: Firmware load failed!"
	run stop
	exit
fi

if hash -v sha1 $kernel_addr_r $filesize *$ramdisk_addr_r; then
	echo "Checksum verified"
else
	echo "ERROR: Checksum failed!"
	run stop
	exit
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
	echo "ERROR: Firmware checksum do not match!"
	run stop
	exit
fi

echo Flash Completed
while true; do sleep 1; done
