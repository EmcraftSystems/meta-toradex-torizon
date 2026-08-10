# NXP i.MX6SoloX SABRE-SD — Torizon machine glue.
#
# The machine itself comes from meta-freescale, on its mainline BSP default.
# This file carries only what Torizon needs on top, and is pulled in by
# conf/template/local.conf's `include conf/machine/include/${MACHINE}.inc`.

# The kernel builds its device trees from KERNEL_DEVICETREE, so there is no
# virtual/dtb provider. ostree-kernel-initramfs_%.bbappend keys an optional
# virtual/dtb dependency off this variable, and leaving it unset breaks the
# task-graph resolve rather than skipping the dependency. Every other
# non-Toradex machine here sets it empty for the same reason.
PREFERRED_PROVIDER_virtual/dtb = ""

# --- flashable SD image -------------------------------------------------------
# Without WKS_FILE:sota, meta-updater's sota.bbclass default (sdimage-sota.wks)
# is in force. That layout has a vfat boot partition and no raw bootloader
# region at all, so it would build a well-formed image the i.MX 6 boot ROM
# cannot boot — no error anywhere. This override is what prevents that.
WKS_FILE:sota = "torizon-imx6sxsabresd-sota.wks"

# The image recipe's format list carries only OSTree/OTA types, so no SD-card
# image of any kind is produced until one is asked for. Plain `wic` is safe to
# append: common-torizon's IMAGE_FSTYPES_REMOVE strips only the wic.gz/bmap/xz
# variants, and the initramfs recipe already removes bare wic, so this cannot
# recreate the circular dependency that other machines work around.
IMAGE_FSTYPES:append = " wic"

# Torizon's boot script, and -- through ostree's bbappend, which keys off whether
# this variable is set at all -- the ostree-uboot-env package in the rootfs.
#
# The bootloader side that reads them is a config fragment on u-boot-fslc, not
# anything here: this board's environment lives in a C header the build cannot
# reach, so the boot command carries its own load addresses.
PREFERRED_PROVIDER_u-boot-default-script = "u-boot-distro-boot"

# Kernel command line. Two traps here, and the i.MX8/9 machines in this directory
# step in the first one:
#
#   - `:sota:imx:append` matches nothing on this build. Bare `imx` is not an
#     active override (MACHINEOVERRIDES resolves to imx-generic-bsp:imx-nxp-bsp,
#     no plain imx; that one comes from meta-toradex-nxp, absent from these
#     BBLAYERS), so the assignment vanishes with no diagnostic.
#   - `:sota:append` is NOT an append to OSTREE_KERNEL_ARGS. It appends to the
#     variant OSTREE_KERNEL_ARGS:sota, which carries no base content and then
#     REPLACES the base under the active override -- silently dropping the
#     distro's own arguments, plymouth.ignore-serial-consoles among them, on a
#     board whose only console is serial.
#
# `:append:sota` is the preserving form, and the shape sl1680.inc/sl2619.inc use.
# The console is UART1 per the machine's own SERIAL_CONSOLES.
OSTREE_KERNEL_ARGS:append:sota = " console=ttymxc0,115200 earlycon root=LABEL=otaroot rootfstype=ext4"
