MediaTek Genio 1200 (Adlink LEC-MTK-i1200 / I-Pi SMARC 1200)
======

This describes how to build Common Torizon OS for the Adlink LEC-MTK-i1200 SoM
(MediaTek Genio 1200 / MT8395 SoC) on the I-Pi SMARC 1200 carrier board.

The MediaTek and Adlink dependency layers are cloned manually after
`repo sync`. They come from MediaTek's IoT Yocto **v25.0** release, which is the
**scarthgap** line (kernel 6.6) and matches the scarthgap Torizon base.

Setup
======
1. Set up the default git user and e-mail:
```
$ git config --global user.email "you@example.com"
$ git config --global user.name "Your Name"
```
2. Install the repo utility to the development host:
```
$ mkdir ~/bin
$ PATH=~/bin:$PATH
$ curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
$ chmod a+x ~/bin/repo
```
3. Create a working directory for the Yocto build, go into that directory:
```
$ cd ~
$ mkdir ~/yocto-workdir
$ cd ~/yocto-workdir
```
4. Initialize the Torizon repository:
```
$ repo init -u https://git.toradex.com/toradex-manifest.git -b scarthgap-7.x.y -m torizon/default.xml
```
5. Sync the repositories:
```
$ repo sync
```
6. Download the MediaTek and Adlink BSP layers into `layers/`. All of these
track MediaTek IoT Yocto v25.0 (scarthgap):
```
# MediaTek core BSP for MT8395: machine, kernel 6.6, TF-A v2.6, U-Boot 2022.10,
# OP-TEE 3.19, Mali DDK r48 / Panfrost (gpu-provider.inc)
$ git -C layers clone -b rity-scarthgap-v25.0 https://gitlab.com/mediatek/aiot/rity/meta-mediatek-bsp.git

# Adlink board layer: lec-mtk-i1200-ufs machine + SMARC DTS
$ git -C layers clone -b rity-scarthgap-v25.0 https://github.com/ADLINK/meta-adlink-mtk.git

# Clang toolchain required by parts of the MediaTek graphics/multimedia stack
$ git -C layers clone -b scarthgap https://github.com/kraj/meta-clang.git
```

Build
======
1. Use the Docker container provided by Toradex to set up the build environment
   in the work directory `~/yocto-workdir` prepared in the previous steps:
```
$ docker run --rm -it --name=crops -v ~/yocto-workdir:/workdir --workdir=/workdir torizon/crops:scarthgap-7.x.y /bin/bash
```
2. Repeat the step of configuring the Git user name and e-mail:
```
$$ git config --global user.email "you@example.com"
$$ git config --global user.name "Your Name"
```
3. In the Docker console set up the environment for the target board:
   `MACHINE=<MACHINE> source setup-environment [BUILDDIR]`, where `MACHINE` is:
 * `lec-mtk-i1200-ufs` - LEC-MTK-i1200 booting from UFS

`BUILDDIR` is the directory where you would like to store the build files. For
example:
```
$$ MACHINE=lec-mtk-i1200-ufs source setup-environment build-lec-mtk-i1200
```

4. Build the Torizon images:
```
$$ bitbake torizon-docker
```

Flash the Device
======
The Genio 1200 is flashed over USB in fastboot/download mode using MediaTek's
[genio-tools](https://gitlab.com/mediatek/aiot/bsp/genio-tools). The build
produces the bootloader (BL2/FIP), GPT layout and the Ostree-based Torizon
image in the deploy directory.

Prerequisites
------
Install `genio-tools` on the development host:
```
$ pip3 install genio-tools
```

1. Set the 4-position boot DIP switch to `1001` (positions 1-4, where `1` = ON
   and `0` = OFF, i.e. ON-OFF-OFF-ON) to boot from UFS. This same setting is
   kept for flashing - `genio-flash` puts the board into download mode itself -
   so it is not changed for the Boot step below. Confirm the switch
   labelling/orientation against the I-Pi SMARC 1200 documentation:
   https://docs.ipi.wiki/smarc/ipi-smarc-1200/
2. Connect the board's USB-C/OTG port to the host and flash from the deploy
   directory:
```
$ cd ~/yocto-workdir/build-lec-mtk-i1200/deploy/images/lec-mtk-i1200-ufs/
$ genio-flash
```
`genio-flash` puts the board into download mode and writes the bootloader and
root filesystem to the on-board storage.

Boot
======
1. Leave the boot DIP switch at `1001` (the UFS boot-device setting used for
   flashing above) and power-cycle the board; no switch change is needed.
2. Connect the serial console (refer to the carrier board documentation for the
   debug UART header) at `921600` baud.
3. Power the target board on and monitor the boot sequence from the serial
   console:
```
...
Common Torizon OS 7.x.y-devel-<timestamp> lec-mtk-i1200-ufs ttyS0

lec-mtk-i1200-ufs login:

```
4. Login to the board using the `torizon/torizon` credentials.

Customizing with TorizonCore Builder
======
TorizonCore Builder (TCB) applies rootfs-level changes (added files, Yocto
packages, preloaded containers, prebuilt kernel modules) to a built image
without a full Yocto rebuild. The `tcb-genio-bridge` wrapper
(`dynamic-layers/meta-mediatek-bsp/recipes-support/tcb-genio-bridge/`) adapts
TCB's raw/WIC contract to the `aiotflash.tar` genio-flash tarball: it unwraps,
unsparses, runs TCB, re-sparses, and repacks with only the rootfs changed.
Device-tree, kernel-argument, U-Boot-env, and splash customizations are out of
scope (TCB rejects them on raw/WIC images).

Prerequisites on the host: `simg2img`/`img2simg`
(`android-sdk-libsparse-utils`) and `torizoncore-builder` on `PATH`.

1. Build the bridge into the deploy directory:
```
$$ bitbake tcb-genio-bridge
```
2. From the deploy directory, collect the wrapper and config:
```
$ cd ~/yocto-workdir/build-lec-mtk-i1200/deploy/images/lec-mtk-i1200-ufs/
$ cp tcb-genio-bridge/tcb-genio-bridge tcb-genio-bridge/tcbuild-genio.yaml .
```
3. Stage the files to overlay under `changes/`:
```
$ mkdir -p changes/etc
$ echo "hello" > changes/etc/hello.txt
```
4. Run the bridge (name the output outside the `*.aiotflash.tar` glob):
```
$ ./tcb-genio-bridge -o custom.tar *.aiotflash.tar
```
   Edit `tcbuild-genio.yaml` for packages, containers, or kernel modules. A
   `.ko` overlaid this way is not `depmod`-indexed; load it with `insmod` of its
   full path, not `modprobe`.
5. Flash the customized tarball (only the rootfs changed):
```
$ tar xf custom.tar
$ cd <extracted-dir>
$ genio-flash system
```
6. Boot and confirm the customization is present.

References
======
* MediaTek IoT Yocto developer guide: https://mediatek.gitlab.io/aiot/doc/aiot-dev-guide/master/
* IoT Yocto v25.0 release notes: https://mediatek.gitlab.io/aiot/doc/aiot-dev-guide/master/sw/yocto/release-notes/iot-yocto-v25.0-release-note.html
* Adlink meta-adlink-mtk: https://github.com/ADLINK/meta-adlink-mtk
* I-Pi SMARC 1200 documentation: https://docs.ipi.wiki/smarc/ipi-smarc-1200/
