FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:common-imx6 = " file://torizon-imx6-usb-gadget.cfg"

# mx6sx-generic-bsp, not a bare "mx6sx": meta-freescale emits only the
# -generic-bsp and -nxp-bsp forms, and an append on an override that does not
# exist is silently no work. Both i.MX 6SoloX machines build from the SABRE-SD
# board, so the .env goes in that board's directory to be found.
SRC_URI:append:mx6sx-generic-bsp = " file://torizon-imx6sx.env file://torizon-imx6sx-env.cfg"

do_configure:prepend:mx6sx-generic-bsp() {
    install -m 0644 ${WORKDIR}/torizon-imx6sx.env ${S}/board/freescale/mx6sxsabresd/torizon-imx6sx.env
}

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
