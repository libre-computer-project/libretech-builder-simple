sudo mkfs.vfat ${loop_dev}p1

local loop_mnt="$(mktemp -d)"
sudo mount ${loop_dev}p1 "$loop_mnt"

#u-boot binary
sudo cp $LBS_UBOOT_PATH/u-boot-rockchip-spi.bin "$loop_mnt"
sha1sum $LBS_UBOOT_PATH/u-boot-rockchip-spi.bin | cut -d " " -f 1 | xxd -r -p | sudo tee "$loop_mnt/u-boot-rockchip-spi.bin.sha1sum" > /dev/null
sudo cp vendor/rockchip/$SPI_FLASH_OVERLAY "$loop_mnt"

#u-boot script
local uboot_script=$(mktemp)
cat "$LBS_SPIFLASH_SCRIPT" | sed "s/%SPI_FLASH_OVERLAY%/$SPI_FLASH_OVERLAY/" | sed "s/%SPI_OF_NODE%/${SPI_OF_NODE//\//\\\/}/" | sed "s/%SPI_DRIVER%/$SPI_DRIVER/" | dd of=$uboot_script
sudo mkimage -A arm -T script -d "$uboot_script" "$loop_mnt/boot.scr"
rm $uboot_script


df $loop_mnt
sudo umount "$loop_mnt"

sudo dd if="$LBS_UBOOT_BIN_FINAL_PATH" of="$loop_dev" conv=fsync,notrunc bs=512 seek=64
