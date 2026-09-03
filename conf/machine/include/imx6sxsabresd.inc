# NXP i.MX6SoloX SABRE-SD — Torizon machine glue.
#
# The machine itself comes from meta-freescale. The BSP is NXP's, not
# meta-freescale's mainline default: base-distro.inc sets IMX_DEFAULT_BSP =
# "nxp", so the kernel is linux-fslc-imx on imx_v7_defconfig.
# This file carries only what is this board's; everything Torizon needs on any
# i.MX 6 is in common-imx6.inc. It is pulled in by conf/template/local.conf's
# `include conf/machine/include/${MACHINE}.inc`.
require common-imx6.inc

# The console is UART1 per the machine's own SERIAL_CONSOLES.
TORIZON_TTY_DEVICE = "ttymxc0,115200"

# aktualizr-default-sec's install action is an eMMC boot-partition swap
# (`mmc bootpart enable`, read back via `mmc extcsd read`). This board has no
# eMMC, only a microSD card, so it fails cleanly at the extcsd read. Disabled
# here.
BL_UPDATE_SUPPORT:imx6sxsabresd = "0"

# The layout file's environment precondition, in this board's numbers:
# CONFIG_ENV_OFFSET=0xE0000 (896 KiB) for CONFIG_ENV_SIZE=0x2000 falls in the gap
# before the payload, so the bootloader's budget is 895 KiB. Today's is 535 KiB.
