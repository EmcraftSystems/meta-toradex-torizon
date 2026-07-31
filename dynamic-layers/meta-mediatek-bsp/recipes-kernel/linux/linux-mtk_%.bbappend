# Kernel modules and vmlinux embed the absolute kernel-source build path via
# __FILE__ in BUG()/WARN() (__bug_table; CONFIG_DEBUG_INFO is off), tripping the
# [buildpaths] QA check on every .ko. The proper fix (rewriting __FILE__ via the
# -fmacro-prefix-map=${STAGING_KERNEL_DIR}=... that kernel-arch.bbclass already
# passes) does not work here: this aarch64 cross gcc does not apply
# -fmacro-prefix-map to __FILE__, and a CONFIG_DEBUG_BUGVERBOSE fragment never
# reaches the kernel at all (the vendor do_copy_defconfig discards every merged
# fragment - see the re-merge below). The warnings are non-fatal - the image
# builds and boots; the embedded paths are only a reproducibility/leak concern -
# so drop the buildpaths check for this recipe to keep the log usable.
WARN_QA:remove = "buildpaths"

# Torizon's required kernel settings. linux-torizon.inc fetches torizon.scc
# unconditionally but torizon.cfg only for the sl1680/imx machines, so the .scc
# would reference a fragment that is not in the include path; the explicit
# SRC_URI entry both resolves it and puts the file at a stable WORKDIR path for
# the re-merge below. The require also restores kernel_do_deploy:append(), whose
# .kernel_scm* files become the OSTree oe.kernel-source metadata.
require recipes-kernel/linux/linux-torizon.inc

SRC_URI:append:lec-mtk1200 = " file://torizon.cfg"

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

# SMARC GPIO line names for the Kemaro build. The vendor do_copy_source drops
# the ADLINK board DTS into the kernel tree *after* do_patch, so a plain SRC_URI
# patch has nothing to apply against; amend the copied DTS in a post-copy step.
SRC_URI:append:lec-mtk1200 = " file://kemaro-smarc-gpio.dtsi"

do_copy_source:append:lec-mtk1200() {
    dts=${S}/arch/arm64/boot/dts/mediatek/lec-mtk-i1200.dts
    [ -f "$dts" ] || bbfatal "kemaro smarc gpio: $dts absent after do_copy_source"
    cat ${WORKDIR}/kemaro-smarc-gpio.dtsi >> "$dts"
}

# The vendor do_copy_defconfig overwrites ${B}/.config from
# adlink_lec_i1200_defconfig after do_kernel_configme, discarding every fragment
# Yocto merged, so torizon.cfg has to be re-applied afterwards. The baseline is
# re-derived from the defconfig rather than taken from ${B}/.config: ${B}
# survives between task runs and do_copy_defconfig is upstream of do_configure,
# so a do_configure-only re-run would otherwise merge onto - and read back - the
# previous run's result. Hooked on do_configure rather than the vendor's own
# do_copy_defconfig, which they already ship at two different graph positions
# keyed on MACHINE; an append to a renamed task is silently never called.
do_configure:prepend:lec-mtk1200() {
    [ -f ${WORKDIR}/torizon.cfg ] || bbfatal "torizon.cfg absent from ${WORKDIR}:" \
        "either it is missing from SRC_URI, or this is an incremental re-run" \
        "against an rm_work-reaped WORKDIR - build linux-mtk clean"
    cp ${S}/arch/arm64/configs/${KERNEL_CONFIG_AARCH64} ${B}/.config
    ${S}/scripts/kconfig/merge_config.sh -m -O ${B} ${B}/.config ${WORKDIR}/torizon.cfg
}

# lec-mtk1200 is the vendor's override; if it is renamed, the SRC_URI entry, the
# re-merge and the read-back below all disappear together and the build stays
# green with the fragment silently dropped. KERNEL_CONFIG_AARCH64 co-varies with
# the clobber itself, so it is the reliable signal that the re-merge is needed.
python () {
    kcfg = d.getVar('KERNEL_CONFIG_AARCH64') or ''
    if kcfg.startswith('adlink_lec_i1200') and \
       'lec-mtk1200' not in (d.getVar('OVERRIDES') or '').split(':'):
        bb.fatal("lec-mtk1200 override missing but %s is in use - "
                 "the torizon.cfg re-merge would silently not apply" % kcfg)
}

# Drop CONFIG_LOCALVERSION_AUTO so the kernel release / module path / vermagic
# don't carry setlocalversion's redundant "-g<sha>-dirty" (the shared kernel tree
# is dirtied by the vendor do_copy_source modifying tracked mt8195.dtsi).
# CONFIG_LOCALVERSION ("-mtk+g<srcrev>") is kept. Done post-configure because the
# vendor do_copy_defconfig overwrites .config (dropping fragments) beforehand.
#
# Then read back what olddefconfig actually produced, since neither
# merge_config.sh nor do_kernel_configcheck can gate this: the former never
# exits non-zero, and the latter suppresses every symbol of a fragment its .scc
# declares non-hardware, which torizon.scc does. Fatal only where absence fails
# silently at run time - docker pull rejects any layer carrying a
# security.capability xattr, and docker run accepts --cpus / --device-read-bps
# and then does not enforce them.
do_configure:append:lec-mtk1200() {
    for f in ${B}/.config ${B}/include/config/auto.conf; do
        [ -f "$f" ] && sed -i 's/^CONFIG_LOCALVERSION_AUTO=y$/# CONFIG_LOCALVERSION_AUTO is not set/' "$f"
    done

    missing=
    for sym in CONFIG_EXT4_FS_SECURITY CONFIG_CFS_BANDWIDTH CONFIG_BLK_DEV_THROTTLING; do
        grep -q "^$sym=y\$" ${B}/.config || missing="$missing $sym"
    done
    if [ -n "$missing" ]; then
        bbfatal "torizon.cfg did not reach the built .config:$missing"
    fi

    while read -r req; do
        case "$req" in ""|\#*) continue ;; esac
        if grep -q "^$req\$" ${B}/.config; then
            continue
        fi
        case "${req%%=*}" in
        # KERNEL_LZ4 does not exist on arm64 (Image.gz is a Makefile target, not
        # a kconfig choice); ZSMALLOC has no prompt while ZSWAP is unset, so it
        # takes =m from ZRAM's select whatever the fragment asks for.
        CONFIG_KERNEL_LZ4|CONFIG_ZSMALLOC)
            bbnote "torizon.cfg: $req not applied - known and expected here" ;;
        *)
            bbwarn "torizon.cfg: $req not applied - needs triage" ;;
        esac
    done < ${WORKDIR}/torizon.cfg
}
