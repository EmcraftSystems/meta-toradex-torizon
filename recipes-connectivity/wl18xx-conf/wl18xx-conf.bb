SUMMARY = "PHY configuration for the TI WiLink 8 Wi-Fi module of imx6sx-blaze"
DESCRIPTION = "\
The wl18xx driver reads ti-connectivity/wl18xx-conf.bin at probe and applies \
the front-end, antenna and TX power settings it carries. Without it the driver \
warns and falls back to built-in defaults. The board has one file per display \
panel, the vendor's, and they are not carried here: the builder supplies them."

# The files are the board vendor's data and are neither stored nor distributed
# with this layer. Place them at these paths before building (docs/README-nxp.md);
# the default is next to the build directory, in the directory `repo sync` ran in.
# A file that is missing is left out and the build warns; a board with that
# panel then runs the driver's built-in defaults.
WL18XX_CONF_BIN_7INCH ?= "${TOPDIR}/../wl18xx-conf-7inch.bin"
WL18XX_CONF_BIN_10INCH ?= "${TOPDIR}/../wl18xx-conf-10inch.bin"

LICENSE = "CLOSED"

COMPATIBLE_MACHINE = "imx6sx-blaze"

inherit systemd

SRC_URI = " \
    file://wl18xx-conf-select \
    file://wl18xx-conf-select.service \
"

python () {
    for var in ('WL18XX_CONF_BIN_7INCH', 'WL18XX_CONF_BIN_10INCH'):
        path = d.getVar(var)
        # Re-parse when the file appears or goes away; its content is tracked through SRC_URI.
        bb.parse.mark_dependency(d, path)
        if os.path.isfile(path):
            d.appendVar('SRC_URI', ' file://' + path)
}

S = "${WORKDIR}"

# The files are per board: keep them out of the shared package feeds of other machines.
PACKAGE_ARCH = "${MACHINE_ARCH}"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

FWDIR = "${nonarch_base_libdir}/firmware/ti-connectivity"

do_install() {
    for panel in 7inch 10inch; do
        if [ "$panel" = 7inch ]; then
            bin="${WL18XX_CONF_BIN_7INCH}"
        else
            bin="${WL18XX_CONF_BIN_10INCH}"
        fi
        if [ ! -f "$bin" ]; then
            bbwarn "No $bin: the image carries no Wi-Fi calibration for the $panel panel. The board vendor supplies the file (docs/README-nxp.md)."
            continue
        fi
        install -d ${D}${FWDIR}/$panel
        install -m 0644 "$bin" ${D}${FWDIR}/$panel/wl18xx-conf.bin
    done

    # The file the driver asks for, and the mount point for the panel's file.
    # Empty, so a panel with no file gets the driver's defaults rather than
    # the other panel's limits: the firmware loader rejects an empty file.
    install -d ${D}${FWDIR}
    install -m 0644 /dev/null ${D}${FWDIR}/wl18xx-conf.bin

    install -d ${D}${libexecdir} ${D}${systemd_system_unitdir}
    install -m 0755 ${WORKDIR}/wl18xx-conf-select ${D}${libexecdir}/
    install -m 0644 ${WORKDIR}/wl18xx-conf-select.service ${D}${systemd_system_unitdir}/
    sed -i -e 's,@LIBEXECDIR@,${libexecdir},g' -e 's,@FWDIR@,${FWDIR},g' \
        ${D}${libexecdir}/wl18xx-conf-select \
        ${D}${systemd_system_unitdir}/wl18xx-conf-select.service
}

SYSTEMD_SERVICE:${PN} = "wl18xx-conf-select.service"

FILES:${PN} = " \
    ${FWDIR} \
    ${libexecdir}/wl18xx-conf-select \
    ${systemd_system_unitdir}/wl18xx-conf-select.service \
"
