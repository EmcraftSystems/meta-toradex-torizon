SUMMARY = "Create a data partition on first boot, after the rootfs"
DESCRIPTION = "Shrinks nothing: on first boot, the rootfs partition is grown to \
DATA_PARTITION_ROOTFS_END_MIB and the rest of the disk becomes a partition \
named data, linked as TDX_ENC_STORAGE_LOCATION for tdx-encrypted. Replaces \
resize-helper in tdx-encrypted builds."
SECTION = "devel"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
    file://data-partition \
    file://data-partition.service \
"

S = "${WORKDIR}"

inherit allarch

PACKAGE_ARCH = "${MACHINE_ARCH}"

# udev ID_PATH glob of the disk that holds the rootfs, set by the machine.
DATA_PARTITION_ID_PATH ?= ""
DATA_PARTITION_ROOTFS_END_MIB ?= "16384"
DATA_PARTITION_LINK = "${@d.getVar('TDX_ENC_STORAGE_LOCATION') or '/dev/tdx-encdata'}"

python () {
    if not d.getVar('DATA_PARTITION_ID_PATH'):
        raise bb.parse.SkipRecipe("DATA_PARTITION_ID_PATH is not set for this machine")
    link = d.getVar('DATA_PARTITION_LINK')
    if not link.startswith('/dev/') or '/' in link[len('/dev/'):]:
        bb.fatal("data-partition: %s must name a /dev/<name> link" % link)
}

def systemd_device_unit(path):
    out = []
    for i, c in enumerate(path.strip('/')):
        if c == '/':
            out.append('-')
        elif (c.isascii() and c.isalnum()) or c in ':_' or (c == '.' and i > 0):
            out.append(c)
        else:
            out.append('\\x%02x' % ord(c))
    return ''.join(out) + '.device'

DATA_PARTITION_DEVICE_UNIT = "${@systemd_device_unit(d.getVar('DATA_PARTITION_LINK'))}"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${S}/data-partition ${D}${sbindir}
    sed -i -e 's|@DATADIR@|${datadir}|' \
           -e 's|@ID_PATH@|${DATA_PARTITION_ID_PATH}|' \
           -e 's|@ROOTFS_END_MIB@|${DATA_PARTITION_ROOTFS_END_MIB}|g' \
           ${D}${sbindir}/data-partition

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/data-partition.service ${D}${systemd_system_unitdir}
    sed -i 's|@SBINDIR@|${sbindir}|' ${D}${systemd_system_unitdir}/data-partition.service

    # The unlock handler waits for the partition this creates.
    install -d ${D}${systemd_system_unitdir}/tdx-enc-handler.service.d
    printf '[Unit]\nRequires=data-partition.service %s\nAfter=data-partition.service %s\n' \
        '${DATA_PARTITION_DEVICE_UNIT}' '${DATA_PARTITION_DEVICE_UNIT}' \
        > ${D}${systemd_system_unitdir}/tdx-enc-handler.service.d/data-partition.conf

    # Only the on-module disk: a removable disk with a "data" partition must
    # never be taken for it and formatted.
    install -d ${D}${nonarch_base_libdir}/udev/rules.d
    printf 'ACTION!="remove", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", ENV{ID_PATH}=="%s", ENV{ID_PART_ENTRY_NAME}=="data", SYMLINK+="%s"\n' \
        '${DATA_PARTITION_ID_PATH}' '${@d.getVar('DATA_PARTITION_LINK')[len('/dev/'):]}' \
        > ${D}${nonarch_base_libdir}/udev/rules.d/70-data-partition.rules
}

FILES:${PN} += "${systemd_system_unitdir} ${nonarch_base_libdir}/udev/rules.d"

RDEPENDS:${PN} = "resize-helper-lib e2fsprogs-resize2fs util-linux-blockdev util-linux-partx"
