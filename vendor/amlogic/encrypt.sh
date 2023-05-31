LBS_VENDOR_finalize(){
	local encrypt_path="$LBS_VENDOR_PATH/$VENDOR_PATH/aml_encrypt_${AML_ENCRYPT}"
	
	local blx_path="$LBS_VENDOR_PATH/$VENDOR_PATH/blx"
	
	if [ ! -d "$blx_path" ]; then
		git clone --depth=1 --single-branch "https://github.com/libre-computer-project/libretech-amlogic-blx.git" "$blx_path"
	fi
	
	$encrypt_path --bl3enc --input "$blx_path"/$BOARD_NAME/bl30_new.bin --output "$blx_path"/$BOARD_NAME/bl30.bin.enc
	$encrypt_path --bl3enc --input "$blx_path"/$BOARD_NAME/bl31.img --output "$blx_path"/$BOARD_NAME/bl31.img.enc
	#$encrypt_path --bl3enc --input "$BL31" --output "$blx_path"/$BOARD_NAME/bl31.img.enc
	$encrypt_path --bl3enc --input "$LBS_UBOOT_PATH"/u-boot.bin --output "$LBS_UBOOT_PATH"/u-boot.bin.enc --compress lz4
	#$encrypt_path --bl3enc --input "$LBS_UBOOT_PATH"/u-boot.bin --output "$LBS_UBOOT_PATH"/u-boot.bin.enc
	$encrypt_path --bl2sig --input "$blx_path"/$BOARD_NAME/bl2_new.bin --output "$blx_path"/$BOARD_NAME/bl2.bin.enc
	$encrypt_path --bootmk --output "$LBS_UBOOT_BIN_FINAL_PATH" --bl2 "$blx_path"/$BOARD_NAME/bl2.bin.enc --bl30 "$blx_path"/$BOARD_NAME/bl30.bin.enc \
		--bl31 "$blx_path"/$BOARD_NAME/bl31.img.enc --bl33 "$LBS_UBOOT_PATH"/u-boot.bin.enc
}
