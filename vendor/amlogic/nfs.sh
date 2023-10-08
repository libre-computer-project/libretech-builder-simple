sudo mkfs.vfat ${loop_dev}p1
local loop_mnt="$(mktemp -d)"
sudo mount ${loop_dev}p1 "$loop_mnt"
sudo mkdir -p "$loop_mnt/EFI/BOOT" "$loop_mnt/dtb"
sudo umount "$loop_mnt"
sudo dd if="$LBS_UBOOT_BIN_FINAL_PATH" of="$loop_dev" conv=fsync,notrunc bs=512 seek=1
