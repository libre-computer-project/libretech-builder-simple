sf probe
load $devtype $devnum $ramdisk_addr_r idbloader.img
sf update $ramdisk_addr_r 0 $filesize
load $devtype $devnum $ramdisk_addr_r u-boot.itb
sf update $ramdisk_addr_r 0x60000 $filesize
echo Flash Completed
while true; do sleep 1; done
