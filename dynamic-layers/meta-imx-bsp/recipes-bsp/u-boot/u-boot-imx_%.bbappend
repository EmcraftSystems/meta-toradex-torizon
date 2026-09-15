require ${@bb.utils.contains_any('MACHINE', 'imx95-19x19-verdin imx93frdm', 'recipes-bsp/u-boot/u-boot-rollback.inc', '', d)}
# `require` is resolved before overrides apply, so the family is read out of MACHINEOVERRIDES.
require ${@'recipes-bsp/u-boot/u-boot-rollback.inc' if 'common-imx6' in (d.getVar('MACHINEOVERRIDES') or '').split(':') else ''}

FILESEXTRAPATHS:prepend:imx95-19x19-verdin := "${THISDIR}/files:"
FILESEXTRAPATHS:prepend:imx93-11x11-lpddr4x-frdm := "${THISDIR}/files:"

SRC_URI:append:imx95-19x19-verdin = " \
    file://bootcommand.cfg \
"

SRC_URI:append:imx93-11x11-lpddr4x-frdm = " \
    file://env_mmc.cfg \
    file://bootcommand.cfg \
"

FILESEXTRAPATHS:prepend:mx6sx-generic-bsp := "${THISDIR}/files/mx6sx:"
FILESEXTRAPATHS:prepend:common-imx6 := "${THISDIR}/files/common-imx6:"
FILESEXTRAPATHS:prepend:imx6sxsabresd := "${THISDIR}/files/imx6sxsabresd:"

# The core rails are an i.MX 6SoloX fact, so every SoloX machine takes this the
# moment it builds this recipe, rather than each one rediscovering it.
SRC_URI:append:mx6sx-generic-bsp = " file://no-ldo-bypass.cfg"

SRC_URI:append:common-imx6 = " file://torizon-imx6sx.env file://torizon-imx6sx-env.cfg"

# Every common-imx6 machine builds U-Boot from the SABRE-SD board directory.
do_configure:prepend:common-imx6() {
    install -m 0644 ${WORKDIR}/torizon-imx6sx.env ${S}/board/freescale/mx6sxsabresd/torizon-imx6sx.env
}

SRC_URI:append:imx6sxsabresd = " file://torizon-boot.cfg file://fastboot.cfg"
