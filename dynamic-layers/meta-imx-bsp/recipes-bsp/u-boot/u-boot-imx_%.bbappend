require ${@bb.utils.contains_any('MACHINE', 'imx95-19x19-verdin imx93frdm imx6sxsabresd', 'recipes-bsp/u-boot/u-boot-rollback.inc', '', d)}

FILESEXTRAPATHS:prepend:imx95-19x19-verdin := "${THISDIR}/files:"
FILESEXTRAPATHS:prepend:imx93-11x11-lpddr4x-frdm := "${THISDIR}/files:"

SRC_URI:append:imx95-19x19-verdin = " \
    file://bootcommand.cfg \
"

SRC_URI:append:imx93-11x11-lpddr4x-frdm = " \
    file://env_mmc.cfg \
    file://bootcommand.cfg \
"

FILESEXTRAPATHS:prepend:imx6sxsabresd := "${THISDIR}/files/imx6sxsabresd:${THISDIR}/../../../meta-freescale/recipes-bsp/u-boot/u-boot-fslc:"

SRC_URI:append:imx6sxsabresd = " file://torizon-imx6sx.env file://torizon-imx6sx-env.cfg file://torizon-boot.cfg file://no-ldo-bypass.cfg file://fastboot.cfg"

do_configure:prepend:imx6sxsabresd() {
    install -m 0644 ${WORKDIR}/torizon-imx6sx.env ${S}/board/freescale/mx6sxsabresd/torizon-imx6sx.env
}
