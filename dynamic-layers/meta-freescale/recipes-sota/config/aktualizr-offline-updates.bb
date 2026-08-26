SUMMARY = "Enable offline updates in Aktualizr-Torizon"
DESCRIPTION = "Configures aktualizr-torizon to accept a signed lockbox from removable media"
SECTION = "base"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MPL-2.0;md5=815ca599c9df247a0c7f619bab123dad"

inherit allarch

SRC_URI = " \
    file://80-offline-updates.toml \
"

do_install:append () {
    install -m 0700 -d ${D}${libdir}/sota/conf.d
    install -m 0644 ${WORKDIR}/80-offline-updates.toml ${D}${libdir}/sota/conf.d/80-offline-updates.toml
}

FILES:${PN} = " \
    ${libdir}/sota/conf.d/80-offline-updates.toml \
"
