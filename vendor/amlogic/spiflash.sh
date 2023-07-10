sudo mkfs.vfat ${loop_dev}p1
local loop_mnt="$(mktemp -d)"
sudo mount ${loop_dev}p1 "$loop_mnt"
sudo cp "$LBS_UBOOT_BIN_FINAL_PATH" "$loop_mnt/u-boot.bin"

sudo mkimage -A arm -T script -d "$LBS_SPIFLASH_SCRIPT" "$loop_mnt/boot.scr"
df $loop_mnt
sudo umount "$loop_mnt"
sudo dd if="$LBS_UBOOT_BIN_FINAL_PATH" of="$loop_dev" conv=fsync,notrunc bs=512 seek=1
#sudo dd if="$sd" of="$loop_dev" conv=fsync,notrunc bs=446 count=1
#sudo dd if="$sd" of="$loop_dev" conv=fsync,notrunc bs=512 skip=1 seek=1
