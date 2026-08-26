FILESEXTRAPATHS:prepend:imx6sxsabresd := "${THISDIR}/imx6sxsabresd:"

# The environment is a raw MMC region compiled into U-Boot, undiscoverable
# without this file — without it greenboot's bootcount reset silently no-ops.
SRC_URI:append:imx6sxsabresd = " file://fw_env.config"
PACKAGE_ARCH:imx6sxsabresd = "${MACHINE_ARCH}"

do_install:append:imx6sxsabresd () {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/fw_env.config ${D}${sysconfdir}/fw_env.config
}

FILES:${PN}-bin:append:imx6sxsabresd = " ${sysconfdir}/fw_env.config"
