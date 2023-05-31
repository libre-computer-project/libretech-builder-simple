LBS_VENDOR_finalize(){
	LBS_VENDOR_GXLIMG_get
	LBS_VENDOR_GXLIMG_sign
}

LBS_VENDOR_AMLOGIC_PATH="$LBS_VENDOR_PATH/$VENDOR_PATH/blx"
LBS_VENDOR_GXLIMG_PATH="$LBS_VENDOR_PATH/$VENDOR_PATH/gxlimg"

LBS_VENDOR_GXLIMG_get(){
	if [ ! -d "$LBS_VENDOR_AMLOGIC_PATH" ]; then
		git clone --depth=1 --single-branch "https://github.com/libre-computer-project/libretech-amlogic-blx.git" "$LBS_VENDOR_AMLOGIC_PATH"
	fi
	if [ ! -d "$LBS_VENDOR_GXLIMG_PATH" ]; then
		git clone --depth=1 --single-branch "https://github.com/repk/gxlimg.git" "$LBS_VENDOR_GXLIMG_PATH"
		make -C "$LBS_VENDOR_GXLIMG_PATH"
	fi
}

LBS_VENDOR_GXLIMG_sign(){
	$LBS_VENDOR_GXLIMG_PATH/gxlimg -t bl2 -s "$blx_path"/$BOARD_NAME/bl2_new.bin "$blx_path"/$BOARD_NAME/bl2.bin.enc
	$LBS_VENDOR_GXLIMG_PATH/gxlimg -t bl3x -c "$blx_path"/$BOARD_NAME/bl30_new.bin "$blx_path"/$BOARD_NAME/bl30.bin.enc
	#$LBS_VENDOR_GXLIMG_PATH/gxlimg -t bl3x -c "$blx_path"/$BOARD_NAME/bl31.img "$blx_path"/$BOARD_NAME/bl31.img.enc
	$LBS_VENDOR_GXLIMG_PATH/gxlimg -t bl3x -c "$BL31" "$blx_path"/$BOARD_NAME/bl31.img.enc
	$LBS_VENDOR_GXLIMG_PATH/gxlimg -t bl3x -c "$LBS_UBOOT_PATH"/u-boot.bin "$LBS_UBOOT_PATH"/u-boot.bin.enc
	#$LBS_VENDOR_GXLIMG_PATH/gxlimg -t fip --bl2 "$blx_path"/$BOARD_NAME/bl2.bin.enc --bl30 "$blx_path"/$BOARD_NAME/bl30.bin.enc --bl31 "$blx_path"/$BOARD_NAME/bl31.img.enc --bl33 "$LBS_UBOOT_PATH"/u-boot.bin.enc "$LBS_UBOOT_PATH"/u-boot-amlogic.bin
	$LBS_VENDOR_GXLIMG_PATH/gxlimg -t fip --bl2 "$blx_path"/$BOARD_NAME/bl2.bin.enc --bl30 "$blx_path"/$BOARD_NAME/bl30.bin.enc --bl31 "$blx_path"/$BOARD_NAME/bl31.img.enc --bl33 "$LBS_UBOOT_PATH"/u-boot.bin.enc "$LBS_UBOOT_BIN_FINAL_PATH"
	dd if="$LBS_UBOOT_BIN_FINAL_PATH" of="$LBS_UBOOT_PATH/u-boot-amlogic.usb.bl2" bs=49152 count=1
	dd if="$LBS_UBOOT_BIN_FINAL_PATH" of="$LBS_UBOOT_PATH/u-boot-amlogic.usb.tpl" skip=49152 bs=1

}
