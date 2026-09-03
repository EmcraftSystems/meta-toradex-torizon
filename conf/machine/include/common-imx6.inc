# Torizon glue common to i.MX 6 machines.
#
# Everything here is a Torizon-and-i.MX 6 fact rather than a board fact. A
# machine include requires this file and sets only what differs: its console
# device, any board-specific kernel argument, and whether its bootloader can be
# updated in place.
#
# The two hooks below are ?= and may be set on either side of the require;
# everything else is a hard =, so a board overriding one must do it after.

# Family override, so a recipe append reaches the i.MX 6 Torizon machines
# without naming each one. Same shape as common-am62xx.inc's common-ti.
MACHINEOVERRIDES =. "common-imx6:"

# The kernel builds its device trees from KERNEL_DEVICETREE, so there is no
# virtual/dtb provider. ostree-kernel-initramfs_%.bbappend keys an optional
# virtual/dtb dependency off this variable, and leaving it unset breaks the
# task-graph resolve rather than skipping the dependency. Every other
# non-Toradex machine here sets it empty for the same reason.
PREFERRED_PROVIDER_virtual/dtb = ""

# Flashable SD image.
# Without WKS_FILE:sota, meta-updater's sota.bbclass default (sdimage-sota.wks)
# has a vfat boot partition and no raw bootloader region, so it would build a
# well-formed image the i.MX 6 boot ROM cannot boot — no error anywhere. A board
# whose bootloader is not a raw copy in the user area overrides this; see the
# layout file's own header.
WKS_FILE:sota = "torizon-imx6-sota.wks"

# The image recipe's format list carries only OSTree/OTA types, so no SD-card
# image of any kind is produced until one is asked for. Plain `wic` is safe to
# append: common-torizon's IMAGE_FSTYPES_REMOVE strips only the wic.gz/bmap/xz
# variants, and the initramfs recipe already removes bare wic, so this cannot
# recreate the circular dependency that other machines work around.
IMAGE_FSTYPES:append = " wic"

# The layout above carries no boot partition: the OSTree sysroot is partition 1
# and the bootloader is a raw copy outside the table.
UBOOT_BOOT_PARTITION_NUMBER = "1"
OTAROOT_PARTITION_NUMBER = "1"

# Torizon's boot script, and - through ostree's bbappend, which keys off
# whether this variable is set at all - the ostree-uboot-env package.
#
# The bootloader side is a config fragment on u-boot-fslc, not anything here:
# an i.MX 6 board's environment typically lives in a C header the build cannot
# reach, so the boot command carries its own load addresses.
PREFERRED_PROVIDER_u-boot-default-script = "u-boot-distro-boot"

# The FECs enumerate as end0/end1. Two of them is an i.MX6SX/6UL property, not
# every i.MX 6 part's; on a single-FEC board end1 is a profile for an interface
# that never appears, which is what networkmanager's own default already does.
NET_NAME:pn-networkmanager = "end"
NET_NUMS:pn-networkmanager = "0 1"

# Kernel command line. Two traps here, and the i.MX8/9 machines in this directory
# step in the first one:
#
#   - `:sota:imx:append` matches nothing on this build. Bare `imx` is not an
#     active override (MACHINEOVERRIDES resolves to imx-generic-bsp:imx-nxp-bsp,
#     no plain imx; that one comes from meta-toradex-nxp, absent from these
#     BBLAYERS), so the assignment vanishes with no diagnostic.
#   - `:sota:append` is NOT an append to OSTREE_KERNEL_ARGS. It appends to the
#     variant OSTREE_KERNEL_ARGS:sota, which carries no base content and then
#     REPLACES the base under the active override - silently dropping the
#     distro's own arguments, plymouth.ignore-serial-consoles among them, on a
#     board whose only console is serial.
#
# `:append:sota` is the preserving form, and the shape sl1680.inc/sl2619.inc use.
# It is written once here so a board contributes its console and its own
# arguments as values; a second `:append:sota` in a machine file would land
# after rootfstype= and reintroduce the ordering problem this form avoids.
#
# TORIZON_BOARD_KERNEL_ARGS is interpolated directly after `earlycon` and
# carries its own separator, so a board writes the leading space itself:
#
#     TORIZON_BOARD_KERNEL_ARGS = " uart_from_osc"
#
# Without it the value fuses onto `earlycon` into one token the kernel drops,
# taking the early console with it. Empty by default, which keeps the expansion
# byte-identical for a board that sets nothing.
TORIZON_TTY_DEVICE ?= "ttymxc0,115200"
TORIZON_BOARD_KERNEL_ARGS ?= ""
OSTREE_KERNEL_ARGS:append:sota = " console=${TORIZON_TTY_DEVICE} earlycon${TORIZON_BOARD_KERNEL_ARGS} root=LABEL=otaroot rootfstype=ext4"
