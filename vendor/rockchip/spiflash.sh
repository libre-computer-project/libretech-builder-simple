sudo mkfs.vfat ${loop_dev}p1
local loop_mnt="$(mktemp -d)"
sudo mount ${loop_dev}p1 "$loop_mnt"
sudo cp $LBS_UBOOT_PATH/u-boot-rockchip-spi.bin "$loop_mnt"
sudo mkimage -A arm -T script -d "$SPIFLASH_SCRIPT" "$loop_mnt/boot.scr"
df $loop_mnt
sudo umount "$loop_mnt"
local sd=$LBS_UBOOT_PATH/u-boot-rockchip.bin
sudo dd if="$sd" of="$loop_dev" conv=fsync,notrunc bs=512 seek=64
