FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:imx6sxsabresd = " file://imx6sxsabresd-fastboot.cfg"
SRC_URI:append:imx6sxsabresd = " file://imx6sxsabresd-torizon-boot.cfg"

# Bootcount, so a failed boot can eventually select altbootcmd. Every other
# bootloader recipe in this layer requires this; u-boot-fslc was the exception,
# which left the `env set altbootcmd` boot.cmd writes with nothing able to act
# on it. Inert until an update is staged -- bootcount_env.c gates both its entry
# points on upgrade_available -- so nothing here changes at run time; it is the
# bootloader half of a mechanism whose remaining halves belong to the OTA work.
require recipes-bsp/u-boot/u-boot-rollback.inc
