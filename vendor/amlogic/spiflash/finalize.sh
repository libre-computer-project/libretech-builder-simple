sudo mkfs.vfat ${loop_dev}p1

local loop_mnt="$(mktemp -d)"
sudo mount ${loop_dev}p1 "$loop_mnt"

#u-boot binary
sudo cp "$LBS_UBOOT_BIN_FINAL_PATH" "$loop_mnt/u-boot.bin"
sha1sum $LBS_UBOOT_BIN_FINAL_PATH | cut -d " " -f 1 | xxd -r -p | sudo tee "$loop_mnt/u-boot.bin.sha1sum" > /dev/null

#u-boot script
sudo mkimage -A arm -T script -d "$LBS_SPIFLASH_SCRIPT" "$loop_mnt/boot.scr"

df $loop_mnt
sudo umount "$loop_mnt"

sudo dd if="$LBS_UBOOT_BIN_FINAL_PATH" of="$loop_dev" conv=fsync,notrunc bs=512 seek=1
