# Secure boot for MediaTek Genio-based platforms

This document describes how secure boot works on the ADLINK LEC-MTK-i1200 (MediaTek Genio 1200, `lec-mtk-i1200-ufs`) when the image is built with the `torizon-signed` class, and what it adds to the general description in `meta-toradex-security`'s `README-secure-boot.md`.

## Introduction

A Genio SoC is in one of two states:

- **Open**: the boot ROM runs any BL2 and any Download Agent sent over USB. Modules leave the factory in this state.
- **Closed**: the hash of the BL2 public key is written to the Public Key Hash0 eFuse and the secure-boot enable (SBC_EN) eFuse is set. The boot ROM then runs only a BL2 signed with that key. Setting the Download Agent Authentication (DAA_EN) eFuse as well makes the boot ROM accept only a signed Download Agent, so `genio-flash` needs the signed Download Agent files from then on.

Writing the eFuses cannot be undone. The tools that sign BL2 and the Download Agent, and the eFuse writer, are provided by MediaTek under NDA.

## Chain of trust

| Stage | Verified by | Key | Where the public key is held |
| :---- | :---------- | :-- | :--------------------------- |
| BL2 | Boot ROM | BL2 key (`efuse.pem`), RSA-3072 | Public Key Hash0 eFuse |
| Firmware image package (BL31, OP-TEE, U-Boot) | BL2, TF-A Trusted Board Boot | ROT key (`rot_key.pem`), RSA-3072 | Hash compiled into BL2 |
| Kernel FIT image (kernel, device trees, initramfs, overlays) | U-Boot | FIT key (`dev`), `sha256,rsa3072` | U-Boot control device tree, required key |
| Root filesystem (OSTree deployment) | Initramfs, composefs with fs-verity | composefs key (`cfs-dev`), Ed25519 | Initramfs, inside the FIT image |

BL2 checks the firmware image package whether or not the module is closed: a package signed with another ROT key stops the boot after BL2 prints the memory size. U-Boot refuses a FIT image signed with another key (`Failed to verify required signature 'key-dev'`) and stops at its prompt.

## Keys

Generate the key set once, keep it outside any build directory, and point every build at it. A closed module is bound to `efuse.pem` and `da.pem` for life: without them it can no longer be recovered over USB, and its BL2 can no longer be replaced.

| File | Purpose |
| :--- | :------ |
| `rot_key.pem` | Signs the firmware image package |
| `dev.key`, `dev.crt` | FIT key: signs the FIT configurations |
| `dev2.key`, `dev2.crt` | FIT key: signs the individual FIT images |
| `cfs-dev.sec`, `cfs-dev.pub` | composefs key: signs the OSTree commit |
| `efuse.pem` | Signs BL2 (NDA tools) |
| `da.pem` | Signs the Download Agent (NDA tools) |

Create the RSA keys with OpenSSL:

```
$ mkdir -p ~/keys/genio && cd ~/keys/genio
$ openssl genrsa -out rot_key.pem 3072
$ openssl genrsa -out efuse.pem 3072
$ openssl genrsa -out da.pem 3072
```

The FIT and composefs keys can be created by a first build with `FIT_GENERATE_KEYS = "1"` and `CFS_GENERATE_KEYS = "1"` and the key directories pointing at the key set; set both to `0` afterwards. The FIT keys must be RSA-3072, because the FIT signature algorithm on this machine is `sha256,rsa3072`.

When the build runs in a container, the key set must be inside a directory the container mounts, and the paths must be the ones the container sees, for example relative to `${TOPDIR}`.

## Configuration

Add to `local.conf`:

```
INHERIT += "torizon-signed"
SECURE_BOOT_ROT_KEY = "/path/to/keys/genio/rot_key.pem"
UBOOT_SIGN_KEYDIR = "/path/to/keys/genio"
UBOOT_SIGN_KEYNAME = "dev"
FIT_GENERATE_KEYS = "0"
CFS_SIGN_KEYDIR = "/path/to/keys/genio"
CFS_SIGN_KEYNAME = "cfs-dev"
CFS_GENERATE_KEYS = "0"
```

The `tdx-signed` class enables the signing on this machine as follows:

| Variable | Description | Value on `lec-mtk-i1200-ufs` |
| :------- | :---------- | :--------------------------- |
| `SECURE_BOOT_ROT_KEY` | Key that signs the firmware image package; BL2 carries its hash | MediaTek's public test key; the build warns until it is set |
| `UBOOT_SIGN_ENABLE` | Sign the kernel FIT image | `1` |
| `FIT_HASH_ALG`, `FIT_SIGN_ALG`, `FIT_SIGN_NUMBITS` | FIT signature algorithm | `sha256`, `rsa3072`, `3072` |
| `UBOOT_SIGN_KEYDIR` | FIT key directory | `${TOPDIR}/keys/fit` |
| `TDX_UBOOT_HARDENING_ENABLE` | U-Boot hardening | `1` |
| `TDX_SECBOOT_REQUIRED_BOOTARGS` | Fixed part of the kernel command line | Set by the Torizon distro configuration |

MediaTek's `secure-boot` distro feature is not used. It would enable the same TF-A options, but it also builds U-Boot without its environment, which the OTA update rollback needs.

## U-Boot hardening

The U-Boot hardening of `meta-toradex-security` applies to MediaTek's U-Boot 2022.10, with these differences from the i.MX and K3 platforms:

- The `scsi` command is on the whitelist, since U-Boot loads the image from UFS through it.
- The Fastboot and `fuse` command protections are not included: this U-Boot is not used over Fastboot and has no `fuse` command.
- The distro and PXE boot methods and DFU are disabled.
- USB is removed from the boot targets.
- The board code writes the DSI bridge and Ethernet PHY registers directly, not through `i2c` commands.
- The board code sets `fitconf_memory` to the module's memory overlay, and the boot script appends it to the FIT configuration with `env set`.
- The required kernel arguments are carried in a device-tree overlay in the FIT image.

## Customizing a signed image

`torizoncore-builder` signs the OSTree commit of a customized image with the same composefs key, and leaves the signed kernel FIT image as built. Kernel arguments and device-tree overlays are therefore set in the image build. See "Signed images" in [README-genio.md](README-genio.md).

## Known issues

- U-Boot does not yet read the closed state from the eFuses, so it treats every module as open: the CLI stays available, and a kernel command-line mismatch is reported but does not stop the boot. `TDX_UBOOT_HARDENING_ENABLE_DBG` simulates the closed state for testing.
- Signing BL2 and the Download Agent, and writing the eFuses, need MediaTek's NDA tools and are not covered by this document yet.
