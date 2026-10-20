SUMMARY = "Bring the CAN interface up at boot"
DESCRIPTION = "Sets the bitrate and transmit queue of can0 and brings it up, so a container needs no network capabilities to use CAN"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd

SRC_URI = "file://can0-up.service"

SYSTEMD_SERVICE:${PN} = "can0-up.service"

do_install () {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/can0-up.service ${D}${systemd_unitdir}/system/
}
