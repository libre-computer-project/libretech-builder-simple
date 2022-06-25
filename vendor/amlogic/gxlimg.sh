local gxlimg_path="$LBS_VENDOR_PATH/$VENDOR_PATH/gxlimg"

if [ ! -d "$gxlimg_path" ]; then
	git clone --depth=1 --single-branch "https://github.com/repk/gxlimg.git" "$gxlimg_path"
	make -C "$gxlimg_path"
fi

local blx_path="$LBS_VENDOR_PATH/$VENDOR_PATH/blx"

if [ ! -d "$blx_path" ]; then
	git clone --depth=1 --single-branch "https://github.com/libre-computer-project/libretech-amlogic-blx.git" "$blx_path"
fi

local sd="$LBS_UBOOT_PATH/u-boot-amlogic.bin"

$gxlimg_path/gxlimg -t bl2 -s "$blx_path"/$BOARD_NAME/bl2_new.bin "$blx_path"/$BOARD_NAME/bl2.bin.enc
$gxlimg_path/gxlimg -t bl3x -c "$blx_path"/$BOARD_NAME/bl30_new.bin "$blx_path"/$BOARD_NAME/bl30.bin.enc
#$gxlimg_path/gxlimg -t bl3x -c "$blx_path"/$BOARD_NAME/bl31.img "$blx_path"/$BOARD_NAME/bl31.img.enc
$gxlimg_path/gxlimg -t bl3x -c "$BL31" "$blx_path"/$BOARD_NAME/bl31.img.enc
$gxlimg_path/gxlimg -t bl3x -c "$LBS_UBOOT_PATH"/u-boot.bin "$LBS_UBOOT_PATH"/u-boot.bin.enc
#$gxlimg_path/gxlimg -t fip --bl2 "$blx_path"/$BOARD_NAME/bl2.bin.enc --bl30 "$blx_path"/$BOARD_NAME/bl30.bin.enc --bl31 "$blx_path"/$BOARD_NAME/bl31.img.enc --bl33 "$LBS_UBOOT_PATH"/u-boot.bin.enc "$LBS_UBOOT_PATH"/u-boot-amlogic.bin
$gxlimg_path/gxlimg -t fip --bl2 "$blx_path"/$BOARD_NAME/bl2.bin.enc --bl30 "$blx_path"/$BOARD_NAME/bl30.bin.enc --bl31 "$blx_path"/$BOARD_NAME/bl31.img.enc --bl33 "$LBS_UBOOT_PATH"/u-boot.bin.enc "$sd"
dd if="$sd" of="$LBS_UBOOT_PATH/u-boot-amlogic.usb.bl2" bs=49152 count=1
dd if="$sd" of="$LBS_UBOOT_PATH/u-boot-amlogic.usb.tpl" skip=49152 bs=1
