local encrypt_path="$LBS_VENDOR_PATH/$VENDOR_PATH/boot"

if [ ! -d "$encrypt_path" ]; then
	git clone --depth=1 --single-branch "git@github.com:libre-computer-project/libretech-amlogic-boot.git" "$encrypt_path"
fi

local blx_path="$LBS_VENDOR_PATH/$VENDOR_PATH/blx"

if [ ! -d "$blx_path" ]; then
	git clone --depth=1 --single-branch "https://github.com/libre-computer-project/libretech-amlogic-blx.git" "$blx_path"
fi

local sd="$LBS_UBOOT_PATH/u-boot-amlogic.bin"

local encrypt_gxl_path="$encrypt_path/fip/gxl/aml_encrypt_gxl"

$encrypt_gxl_path --bl3enc --input "$blx_path"/$BOARD_NAME/bl30_new.bin --output "$blx_path"/$BOARD_NAME/bl30.bin.enc
$encrypt_gxl_path --bl3enc --input "$blx_path"/$BOARD_NAME/bl31.img --output "$blx_path"/$BOARD_NAME/bl31.img.enc
$encrypt_gxl_path --bl3enc --input "$LBS_UBOOT_PATH"/u-boot.bin --output "$LBS_UBOOT_PATH"/u-boot.bin.enc --compress lz4
$encrypt_gxl_path --bl2sig --input "$blx_path"/$BOARD_NAME/bl2_new.bin --output "$blx_path"/$BOARD_NAME/bl2.bin.enc
$encrypt_gxl_path --bootmk --output "$sd" --bl2 "$blx_path"/$BOARD_NAME/bl2.bin.enc --bl30 "$blx_path"/$BOARD_NAME/bl30.bin.enc \
	--bl31 "$blx_path"/$BOARD_NAME/bl31.img.enc --bl33 "$LBS_UBOOT_PATH"/u-boot.bin.enc