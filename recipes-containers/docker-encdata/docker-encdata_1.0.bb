SUMMARY = "Docker storage on the tdx-encrypted data partition"
DESCRIPTION = "Moves /var/lib/docker, including containers pre-provisioned in \
the image, onto the tdx-encrypted partition, and keeps Docker and containerd \
from starting, and the boot from completing, when that partition is not \
mounted."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
    file://docker-encdata \
    file://docker-encdata.service \
    file://encdata.conf \
"

S = "${WORKDIR}"

inherit allarch systemd

TDX_ENC_STORAGE_MOUNTPOINT ??= "/run/encdata"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${S}/docker-encdata ${D}${sbindir}
    sed -i 's|@MOUNTPOINT@|${TDX_ENC_STORAGE_MOUNTPOINT}|' ${D}${sbindir}/docker-encdata

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/docker-encdata.service ${D}${systemd_system_unitdir}
    sed -i 's|@SBINDIR@|${sbindir}|' ${D}${systemd_system_unitdir}/docker-encdata.service

    for unit in docker.service containerd.service; do
        install -d ${D}${systemd_system_unitdir}/$unit.d
        install -m 0644 ${S}/encdata.conf ${D}${systemd_system_unitdir}/$unit.d
    done
}

FILES:${PN} += "${systemd_system_unitdir}"

SYSTEMD_SERVICE:${PN} = "docker-encdata.service"

RDEPENDS:${PN} = "coreutils findutils util-linux-findmnt util-linux-mount tdx-enc-handler"
