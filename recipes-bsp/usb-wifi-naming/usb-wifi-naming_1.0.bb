SUMMARY = "Deterministic interface naming for USB Wi-Fi adapters"
DESCRIPTION = "systemd .link policy naming USB wireless interfaces from their MAC \
address, so two adapters on different USB host controllers cannot compute the same \
predictable name."

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://75-usb-wifi.link"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# Own recipe rather than a systemd bbappend: oe-core packages .link files into
# udev by literal filename, so adding one there would need both a FILES entry
# and PACKAGE_ARCH on systemd itself. nonarch_libdir, not systemd's own
# rootlibexecdir, which that recipe defines locally and is unset everywhere else.
do_install() {
	install -Dm 0644 ${WORKDIR}/75-usb-wifi.link \
		${D}${nonarch_libdir}/systemd/network/75-usb-wifi.link
}

FILES:${PN} = "${nonarch_libdir}/systemd/network/75-usb-wifi.link"

RDEPENDS:${PN} = "udev"
