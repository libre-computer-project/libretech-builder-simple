sf probe
load ${devtype} ${devnum} ${ramdisk_addr_r} u-boot-rockchip-spi.bin
sf update ${ramdisk_addr_r} 0 ${filesize}
echo Flash Completed
pause
