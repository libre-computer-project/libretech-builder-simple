LBS_VENDOR_finalize(){
	LBS_VENDOR_AMLOGIC_get
	LBS_VENDOR_AMLOGIC_sign
}

LBS_VENDOR_AMLOGIC_PATH="$LBS_VENDOR_PATH/$VENDOR_PATH/blx"

LBS_VENDOR_AMLOGIC_get(){
	if [ ! -d "$LBS_VENDOR_AMLOGIC_PATH" ]; then
		git clone --depth=1 --single-branch "https://github.com/libre-computer-project/libretech-amlogic-blx.git" "$LBS_VENDOR_AMLOGIC_PATH"
	fi
}

LBS_VENDOR_AMLOGIC_sign(){
	local encrypt_path="$LBS_VENDOR_AMLOGIC_PATH/aml_encrypt_${AML_ENCRYPT}"
	if [ "$AML_ENCRYPT" = "gxl" ]; then
		$encrypt_path --bl3enc --input "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl30_new.bin --output "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl30.bin.enc
		$encrypt_path --bl3enc --input "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl31.img --output "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl31.img.enc
		$encrypt_path --bl3enc --input "$LBS_UBOOT_PATH"/u-boot.bin --output "$LBS_UBOOT_PATH"/u-boot.bin.enc --compress lz4
		$encrypt_path --bl2sig --input "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl2_new.bin --output "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl2.bin.enc
		$encrypt_path --bootmk --output "$LBS_UBOOT_BIN_FINAL_PATH" --bl2 "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl2.bin.enc --bl30 "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl30.bin.enc \
			--bl31 "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl31.img.enc --bl33 "$LBS_UBOOT_PATH"/u-boot.bin.enc
	elif [ "$AML_ENCRYPT" = "g12b" ]; then
		$encrypt_path --bl30sig --input "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl30_new.bin --output "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl30_new.bin.g12.enc --level v3
		$encrypt_path --bl3sig --input "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl30_new.bin.g12.enc --output "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl30_new.bin.enc --level v3 --type bl30
		$encrypt_path --bl3sig --input "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl31.img --output "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl31.img.enc --level v3 --type bl31
		$encrypt_path --bl3sig --input "$LBS_UBOOT_PATH"/u-boot.bin --compress lz4 --output "$LBS_UBOOT_PATH"/u-boot.bin.enc --level v3 --type bl33
		$encrypt_path --bl2sig --input "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl2_new.bin --output "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl2.n.bin.sig
		$encrypt_path --bootmk --output "$LBS_UBOOT_BIN_FINAL_PATH" \
			--bl2 "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl2.n.bin.sig \
			--bl30 "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl30_new.bin.enc \
			--bl31 "$LBS_VENDOR_AMLOGIC_PATH"/$BOARD_NAME/bl31.img.enc \
			--bl33 "$LBS_UBOOT_PATH"/u-boot.bin.enc \
			--ddrfw1 "$LBS_VENDOR_AMLOGIC_PATH"/init/"$AML_ENCRYPT"/piei.fw \
			--ddrfw2 "$LBS_VENDOR_AMLOGIC_PATH"/init/"$AML_ENCRYPT"/lpddr4_1d.fw \
			--ddrfw3 "$LBS_VENDOR_AMLOGIC_PATH"/init/"$AML_ENCRYPT"/lpddr4_2d.fw \
			--ddrfw4 "$LBS_VENDOR_AMLOGIC_PATH"/init/"$AML_ENCRYPT"/aml_ddr.fw \
			--level v3
			
			#--ddrfw4 "$LBS_VENDOR_AMLOGIC_PATH"/init/"$AML_ENCRYPT"/diag_lpddr4.fw \
			#--ddrfw1 "$LBS_VENDOR_AMLOGIC_PATH"/init/"$AML_ENCRYPT"/ddr4_1d.fw \
			#--ddrfw2 "$LBS_VENDOR_AMLOGIC_PATH"/init/"$AML_ENCRYPT"/ddr4_2d.fw \
			#--ddrfw3 "$LBS_VENDOR_AMLOGIC_PATH"/init/"$AML_ENCRYPT"/ddr3_1d.fw \
	else
		echo "Unknown Amlogic Platform" >&2
		return 1
	fi

	dd if="$LBS_UBOOT_BIN_FINAL_PATH" of="$LBS_OUT_PATH/$LBS_TARGET.usb.bl2" bs=49152 count=1
	dd if="$LBS_UBOOT_BIN_FINAL_PATH" of="$LBS_OUT_PATH/$LBS_TARGET.usb.tpl" skip=49152 bs=1
}
