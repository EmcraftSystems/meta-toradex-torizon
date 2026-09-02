FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:imx6sxsabresd = " file://imx6sxsabresd-fastboot.cfg"
SRC_URI:append:imx6sxsabresd = " file://imx6sxsabresd-torizon-boot.cfg"

# Bootcount, so a failed boot can eventually select the altbootcmd the Torizon
# boot script writes; without it nothing can ever act on that variable. Inert
# until an update is staged -- bootcount_env.c gates both its entry points on
# upgrade_available -- so it changes no run-time behaviour here. Machine-guarded
# because u-boot-fslc is a shared vendor recipe and this is one board's policy.
require ${@bb.utils.contains_any('MACHINE', 'imx6sxsabresd', 'recipes-bsp/u-boot/u-boot-rollback.inc', '', d)}
