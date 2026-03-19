# libretech-builder-simple

## Purpose

Builds bootloaders for Libre Computer boards.

## Prerequisites

Linux machine or virtual machine

## Usage

```
#install pre-requisites via apt or yum
sudo ./setup.sh

git clone --single-branch --depth 1 https://github.com/libre-computer-project/libretech-builder-simple.git

./build.sh BOARD_TARGET
```

## Board Targets

* all-h3-cc-h3
* all-h3-cc-h5
* aml-s805x-ac
* aml-s905x-cc
* aml-s905x-cc-v2
* aml-s905d-pc
* roc-rk3328-cc
* roc-rk3399-pc

## Bootloader Flashing

Default output directory is out/ and is set by LBS_OUT_PATH in configs/build.

Output bootloader needs to be written to the [bootloader offset disk sector](https://github.com/libre-computer-project/libretech-flash-tool/blob/master/lib/bootloader.sh#L5).

`sudo dd if=out/BOARD_TARGET of=/dev/null bs=512 seek=BOOTLOADER_OFFSET`

Replace "BOARD_TARGET", "null", "BOOTLOADER_OFFSET" with the proper file, block device, and bootloader offset respectively. **Be careful not to overwrite the wrong block device!**

### Bootloader Flashing to SPI

For boards with SPI NOR, there is a separate board bootloader target ending with -spiflash.
To flash SPI NOR, dump the output image to a MMC device and the board will boot and flash the SPI NOR.

`sudo dd if=out/BOARD_TARGET-spiflash of=/dev/null bs=1M`

## Advanced Configuration

### Environment Variables

#### U-Boot

| Variable | Description |
|----------|-------------|
| `LBS_UBOOT_MENUCONFIG=1` | Launch interactive menuconfig after defconfig. Prompts to save to defconfig on exit. |
| `LBS_UBOOT_BRANCH_OVERRIDE=BRANCH` | Override the u-boot branch from the board config. |
| `LBS_UBOOT_PATH=PATH` | Override the u-boot source directory (default: `u-boot`). Use this to point to a worktree for development. |
| `LBS_UBOOT_CFGCHECK=1` | Verify u-boot .config against `vendor/libre-computer/u-boot_configs`. |

#### Git

| Variable | Description |
|----------|-------------|
| `LBS_GIT_REMOTE_DEFAULT` | Default git remote for fetching branches (default: `origin`, set in `configs/build`). |
| `LBS_GIT_REMOTE_OVERRIDE="REPO1 REPO2"` | Space-separated list of repos to use alternate remotes for fetching. |

#### Build Targets

| Variable | Description |
|----------|-------------|
| `LBS_TARGET_OVERRIDE=NAME` | Override the output target name. |
| `LBS_OUT_PATH=PATH` | Override the output directory (default: `out`). |

### Git Branch Behavior

`build.sh` calls `LBS_GIT_switchBranch` on the u-boot repo before building:

- If the target branch **exists locally**, it checks out the local branch (no fetch).
- If the target branch **does not exist locally**, it fetches from the remote and creates a local branch from `FETCH_HEAD`.
- If there are **uncommitted tracked files**, it refuses to switch and exits with an error.
- If the repo is in a **bisect**, it skips the branch switch entirely.

### Worktree-Based Development

For board-specific development without modifying the main u-boot repo, use git worktrees in `~/git/u-boot-worktree/`:

```
# Create a board-specific branch from lc-master
cd ~/git/libretech-builder-simple/u-boot
git branch v2026.04/lc-roc-rk3328-cc v2026.04/lc-master

# Create a worktree on that branch
git worktree add ~/git/u-boot-worktree/roc-rk3328-cc v2026.04/lc-roc-rk3328-cc

# Build using the worktree
LBS_UBOOT_PATH=~/git/u-boot-worktree/roc-rk3328-cc \
LBS_UBOOT_BRANCH_OVERRIDE=v2026.04/lc-roc-rk3328-cc \
./build.sh roc-rk3328-cc

# After testing, merge back to lc-master
git checkout v2026.04/lc-master
git merge v2026.04/lc-roc-rk3328-cc

# Clean up
git worktree remove ~/git/u-boot-worktree/roc-rk3328-cc
```

`LBS_UBOOT_PATH` overrides the u-boot source directory. `LBS_UBOOT_BRANCH_OVERRIDE` must match the worktree's branch so `LBS_GIT_switchBranch` does not attempt to switch away from it.

### u-boot menuconfig
```
LBS_UBOOT_MENUCONFIG=1 ./build.sh BOARD_TARGET
```

### Amlogic

Amlogic ATF is not open source so pre-compiled binaries for specific boards are [available in this repository](https://github.com/libre-computer-project/libretech-amlogic-blx.git).

There is an open source implementation of BL31 available in the upstream ATF repository. It can be enabled by changing the `AML_ENCRYPT=gxl` to `AML_GXLIMG=1` in the board configuration file.

## More Information

### ARM Trusted Firmware
[ARM Trusted Firmware Documentation](https://trustedfirmware-a.readthedocs.io/en/latest/plat/index.html)
[ARM Trusted Firmware Design](https://trustedfirmware-a.readthedocs.io/en/latest/design/firmware-design.html)

### U-Boot
[U-Boot Documentation](https://u-boot.readthedocs.io/en/latest/board/index.html)
[U-Boot Usage](https://u-boot.readthedocs.io/en/latest/usage/index.html)

### OPTEE
[StandAloneMM from EDK2 in OPTEE OS](https://optee.readthedocs.io/en/latest/building/efi_vars/stmm.html)

