SUMMARY = "PHY configuration for the Jorjin WG7833-B0A Wi-Fi module"
DESCRIPTION = "\
The wl18xx driver reads ti-connectivity/wl18xx-conf.bin at probe and applies \
the front-end, antenna and TX power settings it carries. Without it the driver \
warns and falls back to built-in defaults that are not this module's. \
This is the module vendor's 2021-04 revision, built from \
WG7833-B0A_INI_rev2_202104.ini by TI's wlconf; its header declares format \
version 7.7, which is what this kernel reads."

# No licence text accompanies the file, so it is left out of the licence
# manifest rather than claimed under one.
LICENSE = "CLOSED"

SRC_URI = "file://wl18xx-conf.bin"

S = "${WORKDIR}"

COMPATIBLE_MACHINE = "imx6sx-blaze"
PACKAGE_ARCH = "${MACHINE_ARCH}"

do_install() {
    install -d ${D}${nonarch_base_libdir}/firmware/ti-connectivity
    install -m 0644 ${WORKDIR}/wl18xx-conf.bin \
        ${D}${nonarch_base_libdir}/firmware/ti-connectivity/wl18xx-conf.bin
}

FILES:${PN} = "${nonarch_base_libdir}/firmware/ti-connectivity/wl18xx-conf.bin"
