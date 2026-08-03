SUMMARY = "Host-side genio/WIC converters for genio-flash images"
DESCRIPTION = "genio2img and img2genio are standalone tools bracketing a \
released torizoncore-builder run against a MediaTek genio-flash \
(aiotflash.tar) image: genio2img unpacks and unsparses the tarball's system \
WIC, and img2genio re-sparses and repacks the result (no Yocto build needed \
in between). Deployed as a single tcb-genio-bridge.tar archive alongside the \
image. Ships the tools plus an example tcbuild configuration."
HOMEPAGE = "https://github.com/EmcraftSystems/meta-toradex-torizon"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PV = "1.0"

SRC_URI = "file://genio2img \
           file://img2genio \
           file://tcbuild-genio.yaml \
"

S = "${WORKDIR}"

inherit deploy

do_configure[noexec] = "1"
do_compile[noexec] = "1"

# Host-side tools: deploy as one archive beside the flashing artifacts (not
# into the rootfs), so it travels with the image as a single file to hand off.
BRIDGE_DEPLOY = "${WORKDIR}/deploy-stage/${BPN}"

do_deploy() {
    install -m 0755 ${S}/genio2img ${BRIDGE_DEPLOY}/genio2img
    install -m 0755 ${S}/img2genio ${BRIDGE_DEPLOY}/img2genio
    install -m 0644 ${S}/tcbuild-genio.yaml ${BRIDGE_DEPLOY}/tcbuild-genio.yaml
    tar --numeric-owner -cf ${DEPLOYDIR}/${BPN}.tar -C ${BRIDGE_DEPLOY}/.. ${BPN}
}
do_deploy[dirs] += "${BRIDGE_DEPLOY}"
do_deploy[cleandirs] += "${BRIDGE_DEPLOY}"
addtask deploy before do_build after do_compile

COMPATIBLE_MACHINE = "lec-mtk-i1200"
