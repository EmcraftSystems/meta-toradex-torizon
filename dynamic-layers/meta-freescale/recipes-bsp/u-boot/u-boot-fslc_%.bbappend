FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:common-imx6 = " file://torizon-imx6-usb-gadget.cfg"

SRC_URI:append:imx6sxsabresd = " file://imx6sxsabresd-fastboot.cfg"
SRC_URI:append:imx6sxsabresd = " file://imx6sxsabresd-torizon-boot.cfg"

# Bootcount, so a failed boot can eventually select the altbootcmd the Torizon
# boot script writes; without it nothing can ever act on that variable. Inert
# until an update is staged -- bootcount_env.c gates both its entry points on
# upgrade_available -- so it changes no run-time behaviour here. Guarded because
# u-boot-fslc is a shared vendor recipe and this is Torizon's rollback policy,
# not every fslc board's. `require` is resolved at parse time, before overrides
# are applied, so the family is read out of MACHINEOVERRIDES rather than keyed
# on it.
require ${@'recipes-bsp/u-boot/u-boot-rollback.inc' if 'common-imx6' in (d.getVar('MACHINEOVERRIDES') or '').split(':') else ''}
