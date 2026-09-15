# NXP i.MX6SoloX SABRE-SD — Torizon machine glue.
#
# The machine definition comes from meta-freescale, which meta-imx requires;
# the BSP is NXP's, so the kernel is linux-imx and the bootloader u-boot-imx.
# This file carries only what is this board's; everything Torizon needs on any
# i.MX 6 is in common-imx6.inc. It is pulled in by the build's own local.conf,
# which setup-environment-imx writes with
# `include conf/machine/include/${MACHINE}.inc`.
require common-imx6.inc

# This board meets the shared layout's environment precondition:
# CONFIG_ENV_OFFSET=0xE0000 (896 KiB) for CONFIG_ENV_SIZE=0x2000 falls in the gap
# before the payload, so the bootloader's budget is 895 KiB. Today's is 631 KiB.

# The console is UART1 per the machine's own SERIAL_CONSOLES.
TORIZON_TTY_DEVICE = "ttymxc0,115200"

# aktualizr-default-sec's install action is an eMMC boot-partition swap
# (`mmc bootpart enable`, read back via `mmc extcsd read`). This board has no
# eMMC, only a microSD card, so it fails cleanly at the extcsd read. Disabled
# here.
BL_UPDATE_SUPPORT:imx6sxsabresd = "0"
