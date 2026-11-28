SUMMARY = "Attach the on-module Bluetooth controller of the LEC-MTK-i1200"
DESCRIPTION = "udev rule and systemd service that attach the HCI UART of the \
module's 88W8997 radio, reached through an on-module USB-to-UART bridge, once \
the Wi-Fi driver has loaded the radio firmware."

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://90-lec-mtk1200-bluetooth.rules \
    file://lec-mtk1200-bluetooth.service \
"

PACKAGE_ARCH = "${MACHINE_ARCH}"
# Module wiring, valid on both the UFS and the QSPI machine.
COMPATIBLE_MACHINE = "^lec-mtk1200$"
INHIBIT_DEFAULT_DEPS = "1"

do_install() {
	install -Dm 0644 ${WORKDIR}/90-lec-mtk1200-bluetooth.rules \
		${D}${nonarch_base_libdir}/udev/rules.d/90-lec-mtk1200-bluetooth.rules
	install -Dm 0644 ${WORKDIR}/lec-mtk1200-bluetooth.service \
		${D}${systemd_system_unitdir}/lec-mtk1200-bluetooth.service
}

FILES:${PN} = "${nonarch_base_libdir}/udev/rules.d/90-lec-mtk1200-bluetooth.rules \
    ${systemd_system_unitdir}/lec-mtk1200-bluetooth.service \
"

# btattach is in the main bluez5 package; ftdi_sio drives the bridge and
# hci_uart provides the H4 line discipline.
RDEPENDS:${PN} = "udev bluez5 kernel-module-ftdi-sio kernel-module-hci-uart"
