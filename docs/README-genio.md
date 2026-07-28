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
The Genio 1200 is flashed over USB in download mode using MediaTek's
[genio-tools](https://gitlab.com/mediatek/aiot/bsp/genio-tools). The build
leaves the bootloader (BL2/FIP), GPT layout, the Ostree-based Torizon image and
the `rity.json` flash descriptor in the deploy directory, and also packs the
same set into a portable genio-flash tarball,
`torizon-docker-lec-mtk-i1200-ufs.aiotflash.tar`. Flash from the deploy
directory when the build host is also the flash host; use the tarball to carry
the image to a separate flash host without copying the whole deploy directory.

Prerequisites
------
Install `genio-tools` on the development host:
```
$ pip3 install genio-tools
```

1. Set the 4-position boot DIP switch to `1001` (positions 1-4, where `1` = ON
   and `0` = OFF, i.e. ON-OFF-OFF-ON) to boot from UFS. This same setting is
   kept for flashing - the board re-enters USB download mode briefly on each
   reset - so it is not changed for the Boot step below. Confirm the switch
   labelling/orientation against the I-Pi SMARC 1200 documentation:
   https://docs.ipi.wiki/smarc/ipi-smarc-1200/
2. Connect the board's micro-USB (OTG) port to the host, then run `genio-flash`.
   On the build host, run it directly from the deploy directory — all partition
   images and `rity.json` are already unpacked there:
```
$ cd ~/yocto-workdir/build-lec-mtk-i1200/deploy/images/lec-mtk-i1200-ufs/
$ genio-flash
```
   To flash from a separate host instead, copy just the tarball across, unpack
   it, and run `genio-flash` from the version-stamped directory it creates:
```
$ tar -xf torizon-docker-lec-mtk-i1200-ufs.aiotflash.tar
$ cd torizon-docker-lec-mtk-i1200-ufs-*/
$ genio-flash
```
`genio-flash` waits for the board's SoC to appear on USB; press the carrier
reset button (or power-cycle) while it waits, so the board re-enters its brief
USB download window. The tool's automatic reset is not available on this
carrier, so this reset is manual. `genio-flash` then writes the bootloader and
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
Common Torizon OS 7.x.y-devel-<timestamp> torizon-lec-mtk-i1200-ufs ttyS0

torizon-lec-mtk-i1200-ufs login:

```
4. Login to the board using the `torizon/torizon` credentials.

Customizing with TorizonCore Builder
======
The `tcb-genio-bridge` wrapper
(`dynamic-layers/meta-mediatek-bsp/recipes-support/tcb-genio-bridge/`) applies a
TorizonCore Builder customization to the genio-flash image. The Genio target
ships as an `aiotflash.tar` wrapping an Android-sparse WIC, which TCB's raw-image
path can't read directly, so the bridge unwraps and unsparses the tarball, runs
TCB against the system image, re-sparses, and repacks it — only the rootfs
changed, partition layout preserved.

The customized image keeps the base image's `/var` state, so it provisions on
the Torizon Cloud exactly as the stock image does. TCB itself restores only the
home directories when it builds the new OSTree deployment, which drops
`/var/sota` — the update client's storage, and where the cloud provisioning
procedure writes `auto-provisioning.json` — so the bridge carries that state
across. The base image's installed-versions record is deliberately not carried:
it names the base commit, and the customized image boots a different one.

Host prerequisites
------
Docker and `simg2img`/`img2simg` (`android-sdk-libsparse-utils`). The bridge
runs TCB from its `torizon/torizoncore-builder` container image, pulled on
first run — no separate `torizoncore-builder` install.

Customization classes
------
The bridge delivers rootfs-level content into the OSTree rootfs:

* File and directory overlays — one `changes/` tree, or several supplied with
  repeatable `-c`, applied in the order listed in `tcbuild-genio.yaml`'s
  `customization.filesystem`. Config files go under `usr/etc/` (the OSTree
  factory-config location), not a top-level `etc/` — a committed `/etc`
  collides with the base `/usr/etc` and the bridge aborts the deploy.
* Yocto packages delivered as installed files (e.g. `usr/bin/`, `usr/lib/`),
  through the same overlay mechanism.
* Prebuilt kernel modules dropped in as `.ko` files. A drop-in is not
  `depmod`-indexed, so load it on the target with `insmod` of its full path,
  not `modprobe`.
* Preloaded containers, from a `docker-compose` bundle (see below).
* Run-time value and registry-credential substitution, so secrets are not
  committed to `tcbuild-genio.yaml` (see `-e` below).

Not supported: `torizoncore-builder` rejects these customisation classes
outright when the target is a raw/WIC image — which the Genio system image
is — regardless of the bridge:

* Kernel module build (the DKMS / in-tree-build route — as opposed to the
  prebuilt `.ko` drop-in above, which is supported)
* Kernel-argument changes
* Device-tree overlays
* U-Boot-env edits (`torizoncore-builder` does not support bootloader
  (U-Boot) customization on any image, not only raw/WIC)
* Secure-boot signing

`torizoncore-builder`'s error is verbatim:

```
Kernel customization is not supported for WIC/raw images. Aborting.
```

A kernel-level change instead needs a BSP rebuild and reflash: an in-tree
driver is enabled as a kernel module on request, and an out-of-tree driver is
delivered as a Yocto recipe.

Command-line reference
------
Kept in sync with `tcb-genio-bridge -h`; update both together when a flag
changes.

```
$ ./tcb-genio-bridge [-o OUTPUT_TAR] [-f TCBUILD_YAML] [-c CHANGES_DIR]... \
      [-b COMPOSE_FILE] [-e VAR]... INPUT_TAR [-- TCB_BUILD_ARG...]
```

* `INPUT_TAR` — the `aiotflash.tar` produced by the Yocto build.
* `-o OUTPUT_TAR` — repacked tarball (default: `<INPUT_TAR without .tar>-custom.tar`).
* `-f TCBUILD_YAML` — the tcbuild config to use (default: `tcbuild-genio.yaml`
  beside the script).
* `-c CHANGES_DIR` — a directory of files to overlay onto the rootfs.
  Repeatable; each is staged under its own basename and applied in the order
  `customization.filesystem` lists it in `tcbuild-genio.yaml` (default:
  `./changes` if present). The basename must be letters, digits, `.`, `_` or
  `-`, and must not begin with `-`. A directory staged here but left out of
  `customization.filesystem` is silently not applied — no error, nothing
  overlaid.
* `-b COMPOSE_FILE` — the `docker-compose` file for a container-preload bundle
  (default: `./docker-compose.yml` if present). Its basename must match the
  tcbuild config's `bundle.compose-file`.
* `-e VAR` — forward `VAR`'s value from the build-host environment to the
  config's `${VAR}` substitution, as `--set VAR=<value>`. Repeatable. `VAR`
  must be exported (a plain shell assignment is not enough — an unexported
  `VAR` is a hard error); an exported-but-empty `VAR` still forwards an empty
  value. Keeps a secret (e.g. a private-registry password) out of the shell
  command line, history, terminal scrollback, and CI logs — but not out of
  the process argument list, which is visible in host `ps` output and in
  `docker inspect` of the tcb container for the run's duration.
* `-- TCB_BUILD_ARG...` — everything after `--` is appended to the
  `torizoncore-builder` build invocation unchanged, e.g.
  `-- --set PASSWORD=secret`. Any of its options can be forwarded this way,
  not only `--set`.

Environment variables:

* `TMPDIR` — working directory for the bridge's intermediate files (see
  "Host free space" below).
* `TCB_GENIO_SKIP_PREFLIGHT=1` — skip the Docker-mount and free-space
  preflight checks.
* `TCB_IMAGE` — override the `torizoncore-builder` container image tag
  (default: `torizon/torizoncore-builder:3`).

Performing image customization
------
Prepare your customization — a `changes/` overlay, a container bundle, or both
(see Customization classes above).

Deploy the bridge and collect it beside the image:
```
$$ bitbake tcb-genio-bridge
$ cd ~/yocto-workdir/build-lec-mtk-i1200/deploy/images/lec-mtk-i1200-ufs/
$ cp tcb-genio-bridge/tcb-genio-bridge tcb-genio-bridge/tcbuild-genio.yaml .
```

Run the bridge against the tarball (see Command-line reference above for the
full flag list):
```
$ ./tcb-genio-bridge -o custom.tar torizon-docker-lec-mtk-i1200-ufs.aiotflash.tar
```
For a preloaded container, uncomment the `bundle:` block in `tcbuild-genio.yaml`
and set `platform: linux/arm64`; the bridge auto-detects `./docker-compose.yml`.

Flash the customized tarball and boot:
```
$ tar xf custom.tar
$ cd torizon-docker-lec-mtk-i1200-ufs-*/
$ genio-flash system
```

The bridge rewrites the rootfs partition in place, so the customization must fit
its free space (about 0.8 GB on the default image). A preloaded container bundle
larger than that is handled by growing the output image, so it is not a limit on
the bundle — but the grow makes the run's disk appetite scale with the bundle.

Host free space
------

The bridge holds the unpacked tarball, the unsparsed input image, the grown
output image, the re-sparsed image and the output tarball at the same time, in
the directory it runs from. Budget

    10 x <tarball> + 2 x <unpacked bundle>

on that filesystem. Without a bundle that is the familiar ten-times-the-tarball
figure; with one the bundle term dominates. A 0.70 GiB tarball with an 8.13 GiB
bundle peaked at 18.9 GiB in measurement — against the 7.0 GiB the tarball alone
would suggest — for which this rule budgets 23.2 GiB.

To work on a different disk, set `TMPDIR` to a directory there — it must be one
the Docker daemon can also reach, so with snap-installed Docker keep it under
your home:

    $ TMPDIR=~/big-disk/scratch ./tcb-genio-bridge -o custom.tar <image>.aiotflash.tar

The container images themselves are fetched into Docker's own storage, which is
usually on a different filesystem (`docker info` reports `Docker Root Dir`);
allow for the bundle there as well.

References
======
* MediaTek IoT Yocto developer guide: https://mediatek.gitlab.io/aiot/doc/aiot-dev-guide/master/
* IoT Yocto v25.0 release notes: https://mediatek.gitlab.io/aiot/doc/aiot-dev-guide/master/sw/yocto/release-notes/iot-yocto-v25.0-release-note.html
* Adlink meta-adlink-mtk: https://github.com/ADLINK/meta-adlink-mtk
* I-Pi SMARC 1200 documentation: https://docs.ipi.wiki/smarc/ipi-smarc-1200/
