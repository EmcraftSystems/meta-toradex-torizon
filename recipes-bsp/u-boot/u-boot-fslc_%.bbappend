FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:imx6sxsabresd = " file://imx6sxsabresd-fastboot.cfg"
