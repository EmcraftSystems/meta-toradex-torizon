SUMMARY = "Host-side torizoncore-builder tooling for genio-flash images"
DESCRIPTION = "Ships two independent customisation paths for a MediaTek \
genio-flash (aiotflash.tar) image. tcb-genio-bridge is a wrapper that \
drives a stock torizoncore-builder end to end (unsparse, build, re-sparse, \
repack) and is deployed as loose files alongside the flashing artifacts — \
the delivery model in production use. genio2img/img2genio are standalone \
converters bracketing a released torizoncore-builder run that carries \
--raw-sector-size (no Yocto build needed in between), for the upstream \
delivery model once that release exists; deployed as a single \
tcb-genio-bridge.tar archive, built but not published alongside the \
wrapper's loose files. Each path ships its own tcbuild configuration, \
since the wrapper's 4Kn handling and the converters' --raw-sector-size \
input are not interchangeable."
HOMEPAGE = "https://github.com/EmcraftSystems/meta-toradex-torizon"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PV = "1.0"

SRC_URI = "file://tcb-genio-bridge \
           file://tcbuild-genio-wrapper.yaml \
           file://genio2img \
           file://img2genio \
           file://tcbuild-genio-converters.yaml \
"

S = "${WORKDIR}"

inherit deploy

do_configure[noexec] = "1"
do_compile[noexec] = "1"

# Host-side tools: the wrapper deploys as loose files (published to the
# customer as-is); the converters deploy as one archive beside the flashing
# artifacts (built for the upstream path, not published in this delivery
# model). Neither goes into the rootfs.
BRIDGE_DEPLOY = "${DEPLOYDIR}/${BPN}"
# Named ${BPN}-converters, not ${BPN}: this basename is also the archive's
# sole top-level member, and it lands beside BRIDGE_DEPLOY under
# DEPLOY_DIR_IMAGE — reusing ${BPN} there would make `tar xf` merge into
# BRIDGE_DEPLOY and clobber its tcbuild-genio.yaml with the converters'.
CONVERTERS_DEPLOY = "${WORKDIR}/deploy-stage/${BPN}-converters"

do_deploy() {
    install -m 0755 ${S}/tcb-genio-bridge ${BRIDGE_DEPLOY}/tcb-genio-bridge
    install -m 0644 ${S}/tcbuild-genio-wrapper.yaml ${BRIDGE_DEPLOY}/tcbuild-genio.yaml

    install -m 0755 ${S}/genio2img ${CONVERTERS_DEPLOY}/genio2img
    install -m 0755 ${S}/img2genio ${CONVERTERS_DEPLOY}/img2genio
    install -m 0644 ${S}/tcbuild-genio-converters.yaml ${CONVERTERS_DEPLOY}/tcbuild-genio.yaml
    tar --numeric-owner -cf ${DEPLOYDIR}/${BPN}.tar -C ${CONVERTERS_DEPLOY}/.. ${BPN}-converters
}
do_deploy[dirs] += "${BRIDGE_DEPLOY} ${CONVERTERS_DEPLOY}"
do_deploy[cleandirs] += "${CONVERTERS_DEPLOY}"
addtask deploy before do_build after do_compile

COMPATIBLE_MACHINE = "lec-mtk-i1200"
