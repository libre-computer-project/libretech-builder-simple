local gxlimg_path="$LBS_VENDOR_PATH/$VENDOR_PATH/gxlimg"

if [ ! -d "$LBS_VENDOR_PATH/$VENDOR_PATH/gxlimg" ]; then
	git clone --depth=1 --single-branch "https://github.com/repk/gxlimg.git" "$LBS_VENDOR_PATH/$VENDOR_PATH/gxlimg"
	make -C "$LBS_VENDOR_PATH/$VENDOR_PATH/gxlimg"
fi

local blx_path="$LBS_VENDOR_PATH/$VENDOR_PATH/blx"

if [ ! -d "$LBS_VENDOR_PATH/$VENDOR_PATH/blx" ]; then
	git clone --depth=1 --single-branch "https://github.com/libre-computer-project/libretech-amlogic-blx.git" "$blx_path"
fi

local sd="$LBS_UBOOT_PATH/u-boot-amlogic.bin"

$gxlimg_path/gxlimg -t bl2 -s "$blx_path"/$BOARD_NAME/bl2_new.bin "$blx_path"/$BOARD_NAME/bl2.bin.enc
$gxlimg_path/gxlimg -t bl3x -c "$blx_path"/$BOARD_NAME/bl30_new.bin "$blx_path"/$BOARD_NAME/bl30.bin.enc
$gxlimg_path/gxlimg -t bl3x -c "$blx_path"/$BOARD_NAME/bl31.img "$blx_path"/$BOARD_NAME/bl31.img.enc
$gxlimg_path/gxlimg -t bl3x -c "$LBS_UBOOT_PATH"/u-boot.bin "$LBS_UBOOT_PATH"/u-boot.bin.enc
#$gxlimg_path/gxlimg -t fip --bl2 "$blx_path"/$BOARD_NAME/bl2.bin.enc --bl30 "$blx_path"/$BOARD_NAME/bl30.bin.enc --bl31 "$blx_path"/$BOARD_NAME/bl31.img.enc --bl33 "$LBS_UBOOT_PATH"/u-boot.bin.enc "$LBS_UBOOT_PATH"/u-boot-amlogic.bin
$gxlimg_path/gxlimg -t fip --bl2 "$blx_path"/$BOARD_NAME/bl2.bin.enc --bl30 "$blx_path"/$BOARD_NAME/bl30.bin.enc --bl31 "$blx_path"/$BOARD_NAME/bl31.img.enc --bl33 "$LBS_UBOOT_PATH"/u-boot.bin.enc "$sd"

sudo mkfs.vfat ${loop_dev}p1
local loop_mnt="$(mktemp -d)"
sudo mount ${loop_dev}p1 "$loop_mnt"
sudo cp "$sd" "$loop_mnt/u-boot.bin"

sudo mkimage -A arm -T script -d "$SPIFLASH_SCRIPT" "$loop_mnt/boot.scr"
df $loop_mnt
sudo umount "$loop_mnt"
sudo dd if="$sd" of="$loop_dev" conv=fsync,notrunc bs=512 seek=1
#sudo dd if="$sd" of="$loop_dev" conv=fsync,notrunc bs=446 count=1
#sudo dd if="$sd" of="$loop_dev" conv=fsync,notrunc bs=512 skip=1 seek=1