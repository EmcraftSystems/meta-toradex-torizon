SUMMARY = "Rootfs disk resize-helper"
SECTION = "devel"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/BSD-2-Clause;md5=cb641bc04cda31daea161b1bc15da69f"

inherit allarch systemd

PACKAGES =+ "${PN}-lib"

RDEPENDS:${PN} += "${PN}-lib e2fsprogs-resize2fs util-linux-fdisk util-linux-blockdev util-linux-partx util-linux-findmnt"
RDEPENDS:${PN}-lib = "gptfdisk"

FILES:${PN}-lib = "${datadir}/resize-helper"

SRC_URI = "file://resize-helper \
    file://resize-helper.service \
    file://gpt-functions \
"

S = "${WORKDIR}"

PACKAGE_ARCH = "${MACHINE_ARCH}"

do_install () {
	install -d ${D}${sbindir}
	install -m 0755 ${S}/resize-helper ${D}${sbindir}
	sed -i 's|@DATADIR@|${datadir}|' ${D}${sbindir}/resize-helper

	install -d ${D}${datadir}/resize-helper
	install -m 0644 ${S}/gpt-functions ${D}${datadir}/resize-helper

	install -d ${D}${systemd_system_unitdir}
	install -m 0644 ${S}/resize-helper.service ${D}${systemd_system_unitdir}
}

SYSTEMD_SERVICE:${PN} = "resize-helper.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"
