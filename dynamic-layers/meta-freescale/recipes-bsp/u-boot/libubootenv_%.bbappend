FILESEXTRAPATHS:prepend:imx6sxsabresd := "${THISDIR}/imx6sxsabresd:"

# The environment is a raw MMC region compiled into U-Boot, undiscoverable
# without this file — without it greenboot's bootcount reset silently no-ops.
# The mechanism is the same on any i.MX 6 board; the offsets in the file are not,
# so each machine supplies its own and points FILESEXTRAPATHS at it.
SRC_URI:append:common-imx6 = " file://fw_env.config"
PACKAGE_ARCH:common-imx6 = "${MACHINE_ARCH}"

do_install:append:common-imx6 () {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/fw_env.config ${D}${sysconfdir}/fw_env.config
}

FILES:${PN}-bin:append:common-imx6 = " ${sysconfdir}/fw_env.config"
