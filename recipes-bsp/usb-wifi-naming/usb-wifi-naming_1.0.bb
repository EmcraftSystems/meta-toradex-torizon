SUMMARY = "Socket-tied interface naming for USB Wi-Fi adapters"
DESCRIPTION = "systemd .link policy naming a USB wireless interface after the SMARC \
USB signal it is attached to, so the name is fixed to the socket and identical on \
every unit; MAC-derived naming is kept as the catch-all for adapters attached \
below those sockets."

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

LINK_FILES = "70-wlan-usb0.link 71-wlan-usb1.link 72-wlan-usb2.link \
              73-wlan-usb3.link 74-wlan-usb4.link 75-wlan-usb5.link \
              76-usb-wifi.link"

SRC_URI = "\
    file://70-wlan-usb0.link \
    file://71-wlan-usb1.link \
    file://72-wlan-usb2.link \
    file://73-wlan-usb3.link \
    file://74-wlan-usb4.link \
    file://75-wlan-usb5.link \
    file://76-usb-wifi.link \
"

# The per-socket files carry SoC controller addresses, so the package is
# machine-specific; lec-mtk1200 is the override token this layer keys on, while
# the MACHINE itself is lec-mtk-i1200-ufs.
PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE = "lec-mtk1200"

# nonarch_libdir, not systemd's own rootlibexecdir, which that recipe defines
# locally and is unset everywhere else.
do_install() {
	for f in ${LINK_FILES}; do
		install -Dm 0644 ${WORKDIR}/$f \
			${D}${nonarch_libdir}/systemd/network/$f
	done
}

FILES:${PN} = "\
    ${nonarch_libdir}/systemd/network/70-wlan-usb0.link \
    ${nonarch_libdir}/systemd/network/71-wlan-usb1.link \
    ${nonarch_libdir}/systemd/network/72-wlan-usb2.link \
    ${nonarch_libdir}/systemd/network/73-wlan-usb3.link \
    ${nonarch_libdir}/systemd/network/74-wlan-usb4.link \
    ${nonarch_libdir}/systemd/network/75-wlan-usb5.link \
    ${nonarch_libdir}/systemd/network/76-usb-wifi.link \
"

RDEPENDS:${PN} = "udev"
