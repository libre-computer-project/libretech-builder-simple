# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

libretech-builder-simple is a bootloader build system for Libre Computer ARM boards. It builds U-Boot and supporting firmware (ATF, Crust, OP-TEE) for Amlogic, Allwinner, and Rockchip SoCs.

## Build Commands

```bash
# Install prerequisites (run once)
sudo ./setup.sh

# Build a specific board target
./build.sh BOARD_TARGET

# Build with interactive U-Boot menuconfig
LBS_UBOOT_MENUCONFIG=1 ./build.sh BOARD_TARGET

# Override U-Boot branch
LBS_UBOOT_BRANCH_OVERRIDE=v2026.01/master ./build.sh BOARD_TARGET

# Build all boards (used for CI)
./build.all.sh
```

## Architecture

### Build Flow (build.sh)

1. Source global config (`configs/build`) and board config (`configs/BOARD_TARGET`)
2. Download/setup GCC toolchains via `lib/gcc.sh`
3. Build firmware stack conditionally:
   - ARM Trusted Firmware (`lib/atf.sh`) if `LBS_ATF=1`
   - Crust SCP firmware (`lib/crust.sh`) if `LBS_CRUST=1`
   - EDK2/OP-TEE (`lib/edk2.sh`, `lib/optee.sh`) if `LBS_OPTEE=1`
4. Build U-Boot (`lib/u-boot.sh`)
5. Finalize: encrypt (Amlogic), package, copy to `out/`

### Configuration Inheritance

Board configs use shell sourcing for inheritance:
```
configs/aml-s905d3-cc
  → configs/amlogic-g12a (SoC family)
    → configs/amlogic (vendor)
      → configs/atf (ATF defaults)
```

### Key Config Variables

- `UBOOT_URL`, `UBOOT_BRANCH`, `UBOOT_TARGET` - U-Boot source and defconfig
- `LBS_ATF`, `LBS_CRUST`, `LBS_OPTEE` - Enable firmware components (0 or 1)
- `LBS_CC` - Cross-compiler prefix (e.g., `aarch64-none-elf-`)
- `AML_ENCRYPT` - Amlogic encryption type (gxl, g12a, g12b)
- `AML_GXLIMG` - Use open-source GXL BL31 instead of vendor binaries

### Directory Structure

- `lib/` - Build orchestration scripts (gcc.sh, atf.sh, u-boot.sh, etc.)
- `configs/` - Board and vendor configuration files
- `vendor/` - Vendor-specific tools and pre-compiled binaries
  - `vendor/amlogic/blx/` - Pre-compiled Amlogic BL2/BL30/BL31 (required for encryption)
  - `vendor/amlogic/encrypt.sh` - Amlogic bootloader signing/encryption
- `out/` - Build output directory

### Vendor-Specific Notes

**Amlogic**: Uses pre-compiled vendor binaries from `vendor/amlogic/blx/` and encryption via `vendor/amlogic/encrypt.sh`. The `AML_ENCRYPT` variable triggers the encryption pipeline.

**Allwinner**: Builds ATF and Crust from source. Requires `or1k-elf` compiler for Crust.

**Rockchip**: Builds ATF from source. Uses `boot_merger` from `vendor/rockchip/bin/`.

## U-Boot Branching Model

All board support commits go on the shared `lc-master` branch (e.g. `v2026.04/lc-master`). The builder's `UBOOT_BRANCH` points to `lc-master`. Do NOT create per-board branches directly in the builder's `u-boot/` repo.

Per-board branches are for **worktree-based development**: branch from `lc-master`, create a worktree in `~/git/u-boot-worktree/`, develop and test there using `LBS_UBOOT_PATH` and `LBS_UBOOT_BRANCH_OVERRIDE`, then merge back to `lc-master` when done. See `readme.md` "Worktree-Based Development" for the full workflow.

## Output Files

After successful build, `out/` contains:
- `BOARD_TARGET` - Bootloader binary (flash this)
- `BOARD_TARGET.config` - U-Boot configuration
- `BOARD_TARGET.dtb` - Device tree binary
- `BOARD_TARGET.dts` - Device tree source
- `BOARD_TARGET-spiflash` - SPI NOR bootable image (if applicable)

## Flashing

MMC bootloader offsets are platform-dependent (e.g., sector 1 for Amlogic, sector 16 for Allwinner). See [libretech-flash-tool](https://github.com/libre-computer-project/libretech-flash-tool) for board-specific offsets and flashing utilities.

SPI NOR flashing requires separate programming tools/processes not included in this repository. The `-spiflash` output images are meant to be programmed to NOR flash, not written via dd.
