sf probe
load $devtype $devnum $ramdisk_addr_r u-boot.bin
sf update $ramdisk_addr_r 0 $filesize
echo Flash Completed
while true; do sleep 1; done
