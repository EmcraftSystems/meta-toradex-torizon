Setup
======
1. If you don't have the `repo` tool installed, please refer to [Build Torizon OS From Source with Yocto Project](https://developer.toradex.com/torizon/in-depth/build-torizoncore-from-source-with-yocto-projectopenembedded/#download-metadata).
2. Initialize and sync the repo manifest for NXP:
```bash
$ mkdir common-torizon; cd common-torizon
$ repo init -u https://git.toradex.com/toradex-manifest.git -b scarthgap-7.x.y -m common-torizon/nxp/default.xml
$ repo sync -j 10
```
We **strongly recommend** using the `default.xml` manifest. The `integration.xml` and `next.xml` are development manifests used internally and they might be unstable.
`default.xml` is the manifest used for our releases, so they are reliable.  

Alternatively, you can manually clone all layers one by one. Refer to the section [_Manual Setup_](#manual-setup) at the end of this document to learn how.

Build
======
| Board | MACHINE | Status |
|---|---|---|
| FRDM i.MX 93 | imx93frdm  | Supported  |
| Verdin i.MX95 EVK  | imx95-19x19-verdin  | Supported |
| SABRE-SD i.MX 6SoloX | imx6sxsabresd | Supported |

1. Source `setup-environment`, specifying the machine to build with the MACHINE variable e.g.:
```bash
$ MACHINE=imx93frdm . setup-environment <build-directory>
```
If a build directory is not given, the script will create one named `build`, where all build artifacts will be stored.

2. Inside the build directory, start the build e.g.:
```bash
$ bitbake torizon-docker
```
All artifacts should be inside `<build-directory>/deploy/images/${MACHINE}`.

Flash the Device (Verdin i.MX95 EVK)
======
1. Change board boot switch to `ON OFF OFF ON` (CM33 Serial Download)
2. Download [uuu](https://github.com/nxp-imx/mfgtools/releases/tag/uuu_1.5.201) or build it from [source](https://github.com/nxp-imx/mfgtools)
3. Download image:
```bash
sudo ./uuu -b emmc_all <bootloader> <wic image>
```
For example, flashing a local build we've generated:
```bash
sudo ./uuu -v -b emmc_all imx-boot-imx95-19x19-verdin-sd.bin-flash_all torizon-docker-imx95-19x19-verdin-7.0.0-devel-20250602173442+build.0.wic.zst
```
4. Change boot switch to `ON OFF ON OFF` (CM33 eMMC) to boot from eMMC.

Flash the Device (FRDM i.MX93 SDCard)
======
1. Change board boot switch to `ON ON OFF OFF` to boot from SDCard.
2. Flash the wic image to an SDCard.
```bash
zstdcat if=torizon-docker-imx93-11x11-lpddr4x-frdm-7.0.0-devel-20250602173442+build.0.wic.zst | sudo dd of=<sdcard-device-node>
```
3. Insert the SDCard.
4. Power on the board.

Flash the Device (FRDM i.MX93 eMMC)
======
Coming Soon

Flash the Device (SABRE-SD i.MX 6SoloX SDCard)
======
This board has no eMMC and boots only from the SD card in slot `J4`
(silkscreened `SD4 BOOT`). Its `uuu -b sd_all` built-in exists but does
not work here — it ends in `flash bootloader`, a command this board's
mainline U-Boot does not implement — so this uses a small custom script
instead. Download [uuu](https://github.com/nxp-imx/mfgtools/releases/tag/uuu_1.5.201)
or build it from [source](https://github.com/nxp-imx/mfgtools); version
1.4.182 or later is required (the script itself checks and refuses an
older one).

1. Insert a microSD card into `J4` (`SD4 BOOT`). Its entire contents are
   overwritten by this procedure.
2. Set boot-mode switch `S1` position 1 OFF, position 2 ON, to select
   the i.MX 6 ROM's serial-downloader strap (`BOOT_MODE[1:0] = 01`). The
   `BOOT_CFG` switches (`SW10`–`SW12`) stay at the board's factory
   SD-boot position (SD Boot, 4-bit bus, SDHC4 bus) — nothing to change
   there.
3. Connect the board's USB OTG port to the host and power it on (or
   reset it) with the switch in that position. Confirm it enumerates as
   the i.MX 6 boot ROM's serial downloader:
```bash
$ sudo uuu -lsusb
	Path	 Chip	 Pro	 Vid	 Pid	 BcdVersion	 Serial_no
	====================================================================
	1:2	 MX6SX	 SDP:	 0x15A2	0x0071	 0x0001	
```
4. Download `scripts/imx6sxsabresd.uuu` from this repository into the
   same directory as the built image and bootloader. The script opens
   them by their stable names, `torizon-docker-imx6sxsabresd.wic` and
   `u-boot.imx` — if the copy you have carries a version suffix, link
   the stable names to it:
```bash
$ ln -sf torizon-docker-imx6sxsabresd-<version>.wic torizon-docker-imx6sxsabresd.wic
$ ln -sf u-boot-<version>.imx u-boot.imx
```
5. Flash the whole card, using `uuu` >= 1.4.182 (the script itself checks
   and refuses an older one):
```bash
$ sudo uuu imx6sxsabresd.uuu
```
For example, flashing a local build:
```bash
$ sudo uuu imx6sxsabresd.uuu
uuu (Universal Update Utility) for nxp imx chips -- libuuu-1.5.243

Success 1    Failure 0
```
6. Once the transfer completes, set `S1` position 1 ON, position 2 OFF,
   to select internal boot (`BOOT_MODE[1:0] = 10`), then press and
   release the board's reset button `SW3` so the ROM proceeds to the SD
   card.

Using Torizon OS on the SABRE-SD i.MX 6SoloX
======
A few things are specific to this board and worth knowing before using
the features Torizon OS provides:

- **No eMMC — the SD card is the only storage.** Where Torizon
  documentation or tooling elsewhere refers to eMMC (health monitoring,
  the offline-update lockbox medium), this board has none; the SD card
  in `J4` is both the boot and the root filesystem device.
- **Ethernet interfaces are `end0` and `end1`**, not `eth0`/`eth1` — this
  board isn't a Toradex module, so the interface names come from its own
  device tree rather than Toradex's naming convention.
- **Remote access needs a restart after first Cloud provisioning.** The
  service that carries remote-access sessions only starts if the
  device's private key already exists, and that check runs once at boot
  — so on a freshly provisioned device (via the Cloud's device-page
  command), run `sudo systemctl start remote-access` once, or reboot the
  device, before expecting a remote session to connect.
- **The `hello-world` container demo needs no board-specific
  configuration.** `docker run hello-world` pulls Docker's own
  multi-architecture image and runs it exactly as documented for any
  Torizon device.

See "OTA Updates and Rollback (SABRE-SD i.MX 6SoloX)" below for
updating this board over the air.

OTA Updates and Rollback (SABRE-SD i.MX 6SoloX)
======
The standard Torizon Cloud OTA flow works on this board with no
board-specific steps: publish a target's OSTree commit, deploy it to a
provisioned device, and `aktualizr-torizon` downloads and deploys it via
`ostree admin deploy`, the same way it does on any Torizon device.

Provisioning
------
Provisioning is the standard Cloud-issued one-line device command (see
the Torizon Cloud documentation). Torizon OS also ships the
`auto-provisioning` systemd service as a second route — useful where
the one-line command's short validity window is impractical, such as
repeated bench testing:

1. Extract `client_id`, `secret` and `token_endpoint` from the account's
   `credentials.zip` export (its `provision.json`) into a minimal JSON
   file, and place it at `/var/sota/auto-provisioning.json` on the
   device (root-owned directory; needs `sudo`).
2. Start the service (or reboot the device — it also runs at boot):
```bash
$ sudo systemctl start auto-provisioning.service
```
3. Confirm it registered:
```bash
$ sudo journalctl -u auto-provisioning.service | grep 'Device successfully provisioned'
Device successfully provisioned
```
It will not re-provision a device that already has one
(`/var/sota/import/pkey.pem` already present is treated as done).

Deploying an update
------
1. On the Cloud account's Devices page, confirm the device is listed
   and note its name.
2. On the Cloud account's Updates page, create an update targeting the
   device with the desired `torizon-docker` target.
3. Trigger an update check on the device, rather than waiting for its
   normal poll interval:
```bash
$ sudo systemctl restart aktualizr-torizon
```
4. The device downloads the update, deploys it with `ostree admin
   deploy`, and reboots into it — no further action needed.
5. After the reboot, confirm the new version is running:
```bash
$ cat /etc/os-release | grep VERSION_ID
```

Rollback
------
Automatic rollback (`rollback_mode=uboot_masked`, in Torizon's own
terms) is enabled by two settings already carried in this board's
bootloader configuration — `bootlimit=3` and a `CONFIG_BOOTCOMMAND`
fragment giving U-Boot's own boot-counting a deployment to fall back
to.

1. Deploying an update (above) sets `upgrade_available=1` in the U-Boot
   environment.
2. A healthy boot — as Greenboot defines it — clears that flag; nothing
   further happens.
3. A boot that never reaches that point, across 3 attempts, switches
   U-Boot to its alternate boot command instead, which boots the
   previous deployment and records `rollback=1` — with no manual
   recovery step on the board.
4. Confirm a rollback happened, if one was expected:
```bash
$ sudo fw_printenv rollback
rollback=1
```

Manual Setup
======
1. Create the project folder:
```bash
$ mkdir common-torizon; cd common-torizon
```
2. Clone NXP's BSP layers:
```bash
$ repo init -u https://github.com/nxp-imx/imx-manifest.git -b imx-linux-scarthgap -m imx-6.6.52-2.2.0.xml
$ repo sync -j 10
```
3. Clone `meta-toradex-torizon` layer, and its dependencies:
```bash
$ git clone https://github.com/torizon/meta-toradex-torizon.git -b scarthgap-7.x.y sources/meta-toradex-torizon
$ git clone https://github.com/uptane/meta-updater.git -b scarthgap sources/meta-updater
$ ln -s sources/meta-toradex-torizon/scripts/setup-environment setup-environment
```

Additional Setup for i.MX93 FRDM boards
======
1. Clone NXP's BSP layers specific to the i.MX93 FRDM board:
```bash
$ git clone https://github.com/nxp-imx-support/meta-imx-frdm.git -b imx-frdm-4.0 sources/meta-imx-frdm
$ ln -s sources/meta-imx-frdm/tools/imx-frdm-setup.sh imx-frdm-setup.sh
```
