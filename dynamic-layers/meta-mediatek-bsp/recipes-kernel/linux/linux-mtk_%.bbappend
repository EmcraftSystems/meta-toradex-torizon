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

# Torizon's required kernel settings. linux-torizon.inc adds torizon.cfg to
# SRC_URI only for the sl1680/imx machines, and the re-merge below reads it from
# the unpack directory, so it has to be fetched explicitly here. The require also
# restores kernel_do_deploy:append(), whose .kernel_scm* files become the OSTree
# oe.kernel-source metadata.
require recipes-kernel/linux/linux-torizon.inc

SRC_URI:append:lec-mtk1200 = " file://torizon.cfg"

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

# The vendor do_copy_defconfig overwrites ${B}/.config from the ADLINK defconfig
# after do_kernel_configme, discarding every fragment Yocto merged. Re-derive the
# baseline from that same defconfig rather than reusing ${B}/.config, which
# survives between task runs: a do_configure-only re-run would otherwise merge
# onto - and read back - the previous run's result. Hooked on do_configure, not
# on the vendor's own task, which they already ship at two graph positions keyed
# on MACHINE; an append to a renamed task is silently never called.
do_configure:prepend:lec-mtk1200() {
    [ -f ${WORKDIR}/torizon.cfg ] || bbfatal "torizon.cfg absent from ${WORKDIR}:" \
        "it is missing from SRC_URI, or this is an incremental re-run against an" \
        "rm_work-reaped WORKDIR (build linux-mtk clean), or UNPACKDIR no longer" \
        "defaults to WORKDIR"
    cp ${S}/arch/arm64/configs/${KERNEL_CONFIG_AARCH64} ${B}/.config
    ${S}/scripts/kconfig/merge_config.sh -m -O ${B} ${B}/.config ${WORKDIR}/torizon.cfg
}

# lec-mtk1200 is the vendor's override; if it is renamed, the SRC_URI entry, the
# re-merge and the read-back below all disappear together and the build stays
# green with the fragment silently dropped. Detect that by mirroring the
# vendor's own condition for scheduling the clobber - any ADLINK defconfig on a
# machine other than absolute-vision, which gets the task before configme and so
# keeps its fragments.
python () {
    kcfg = d.getVar('KERNEL_CONFIG_AARCH64') or ''
    if kcfg.startswith('adlink_') and d.getVar('MACHINE') != 'absolute-vision' \
       and 'lec-mtk1200' not in (d.getVar('OVERRIDES') or '').split(':'):
        bb.fatal("lec-mtk1200 override missing but %s is in use - "
                 "the torizon.cfg re-merge would silently not apply" % kcfg)
}

# Drop CONFIG_LOCALVERSION_AUTO so the kernel release / module path / vermagic
# don't carry setlocalversion's redundant "-g<sha>-dirty" (the shared kernel tree
# is dirtied by the vendor do_copy_source modifying tracked mt8195.dtsi).
# CONFIG_LOCALVERSION ("-mtk+g<srcrev>") is kept. Done post-configure because the
# vendor do_copy_defconfig overwrites .config (dropping fragments) beforehand.
do_configure:append:lec-mtk1200() {
    for f in ${B}/.config ${B}/include/config/auto.conf; do
        [ -f "$f" ] && sed -i 's/^CONFIG_LOCALVERSION_AUTO=y$/# CONFIG_LOCALVERSION_AUTO is not set/' "$f"
    done

    # Read back what olddefconfig produced. merge_config.sh never exits non-zero,
    # and do_kernel_configcheck ignores every symbol of a fragment whose .scc
    # declares it non-hardware, which torizon.scc does - so neither can gate this.
    # Fatal only where absence is silent at run time: ext4 rejects the
    # security.capability xattr that docker pull writes, --cpus is accepted and
    # not enforced, and no cgroup can carry a block-I/O limit at all.
    missing=
    for sym in CONFIG_EXT4_FS_SECURITY CONFIG_CFS_BANDWIDTH CONFIG_BLK_DEV_THROTTLING; do
        grep -qxF "$sym=y" ${B}/.config || missing="$missing $sym"
    done
    if [ -n "$missing" ]; then
        bbfatal "torizon.cfg did not reach the built .config:$missing"
    fi

    # "# CONFIG_X is not set" is a request to disable, not a comment.
    while read -r req || [ -n "$req" ]; do
        case "$req" in
        "# CONFIG_"*" is not set") sym=${req#\# }; sym=${sym%% *} ;;
        ""|\#*)                    continue ;;
        *)                         sym=${req%%=*} ;;
        esac
        if grep -qxF "$req" ${B}/.config; then
            continue
        fi
        case "$sym" in
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

# The image recipe reads these three with a helper that returns "" for a file it
# cannot open, so a broken deploy path commits an empty oe.kernel-source triple
# and nothing anywhere reports it.
kernel_do_deploy:append:lec-mtk1200() {
    for f in .kernel_scmurl .kernel_scmbranch .kernel_scmversion; do
        [ -s ${DEPLOYDIR}/$f ] || bbfatal "kernel provenance: ${DEPLOYDIR}/$f missing or empty"
    done
}
