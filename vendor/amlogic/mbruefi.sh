. $LBS_VENDOR_PATH/$VENDOR_PATH/gxlimg.sh

sudo mkfs.vfat -F 32 ${loop_dev}p1
local loop_mnt="$(mktemp -d)"
sudo mount ${loop_dev}p1 "$loop_mnt"
sudo cp "$sd" "$loop_mnt/u-boot.bin"
sudo cp "$MBRUEFI_SCRIPT" "$loop_mnt/"
sudo cp "$DISTROFIX_SCRIPT" "$loop_mnt/"

df $loop_mnt
sudo umount "$loop_mnt"
sudo dd if="$sd" of="$loop_dev" conv=fsync,notrunc bs=512 seek=1
#sudo dd if="$sd" of="$loop_dev" conv=fsync,notrunc bs=446 count=1
#sudo dd if="$sd" of="$loop_dev" conv=fsync,notrunc bs=512 skip=1 seek=1
