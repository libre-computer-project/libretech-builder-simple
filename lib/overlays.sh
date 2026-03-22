#!/bin/bash

# Build DT overlay FIT image from libretech-wiring-tool (LWT) DTBOs.
#
# Derives the LWT board directory from BOARD_NAME by progressively stripping
# trailing -suffix components until a matching LWT dt/ directory is found.
# Uses LWT Makefile's BOARD= variable to build only that board's overlays.
#
# Two-phase build:
#   LBS_OVERLAYS_build_fit — compile DTBOs and package into a FIT image
#   LBS_OVERLAYS_embed     — write FIT into the raw spiflash image

NOR_FIT_OFFSET=0x200000

LBS_OVERLAYS_build_fit() {
	if [ -z "$LBS_LWT_PATH" ] || [ ! -d "$LBS_LWT_PATH" ]; then
		if [[ "$LBS_TARGET" == *-spi ]]; then
			echo "ERROR: libretech-wiring-tool not found at $LBS_LWT_PATH, required for -spi targets" >&2
			exit 1
		fi
		return
	fi

	# Derive LWT board directory from BOARD_NAME
	local lwt_board="$BOARD_NAME"
	while [ ! -d "$LBS_LWT_PATH/libre-computer/$lwt_board/dt" ]; do
		local stripped="${lwt_board%-*}"
		if [ "$stripped" = "$lwt_board" ]; then
			echo "overlays: no LWT dt/ directory found for $BOARD_NAME"
			return
		fi
		lwt_board="$stripped"
	done

	local lwt_dt_path="$LBS_LWT_PATH/libre-computer/$lwt_board/dt"
	echo "overlays: using LWT board $lwt_board"

	# Build overlays for this board only
	make -C "$LBS_LWT_PATH" BOARD_NAME="$lwt_board"

	# Collect .dtbo files
	local staging="$LBS_OUT_PATH/.overlays-staging"
	rm -rf "$staging"
	mkdir -p "$staging"

	local count=0
	for dtbo in "$lwt_dt_path"/*.dtbo; do
		[ -f "$dtbo" ] || continue
		cp -L "$dtbo" "$staging/"
		count=$((count + 1))
	done

	if [ "$count" -eq 0 ]; then
		echo "overlays: no .dtbo files found"
		rm -rf "$staging"
		return
	fi

	echo "overlays: packaging $count DTBOs into FIT"

	# Generate FIT .its
	local its_file="$LBS_OUT_PATH/${LBS_TARGET}.its"
	local fit_file="$LBS_OUT_PATH/${LBS_TARGET}.fit"

	cat > "$its_file" <<'HEADER'
/dts-v1/;

/ {
	description = "DT Overlay FIT";
	#address-cells = <1>;

	images {
HEADER

	for dtbo in "$staging"/*.dtbo; do
		[ -f "$dtbo" ] || continue
		local name=$(basename "$dtbo" .dtbo)
		cat >> "$its_file" <<EOF
		${name} {
			description = "${name}";
			data = /incbin/(".overlays-staging/${name}.dtbo");
			type = "flat_dt";
			compression = "none";
		};
EOF
	done

	cat >> "$its_file" <<'FOOTER'
	};
};
FOOTER

	# Build FIT
	"$LBS_UBOOT_PATH/tools/mkimage" -f "$its_file" "$fit_file"

	# Export path for embed phase and finalize.sh
	LBS_OVERLAYS_FIT="$fit_file"

	rm -rf "$staging"
}

