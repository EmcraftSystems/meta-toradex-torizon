require recipes-kernel/linux/linux-torizon.inc

# NXP's Kernel recipe uses this variable to manually append fragments
# to the generated .config.
DELTA_KERNEL_DEFCONFIG:append = "torizon.cfg"

FILESEXTRAPATHS:prepend:mx6-generic-bsp := "${THISDIR}/files:"
SRC_URI:append:mx6-generic-bsp = " file://torizon-container.cfg"
DELTA_KERNEL_DEFCONFIG:append:mx6-generic-bsp = " torizon-container.cfg"
SRC_URI:append:mx6-generic-bsp = " file://no-fw-fallback.cfg"
DELTA_KERNEL_DEFCONFIG:append:mx6-generic-bsp = " no-fw-fallback.cfg"

SRC_URI:append:imx6sxsabresd = " file://0001-ARM-dts-imx6sx-sdb-reva-reset-through-the-internal-wa.patch"

SRC_URI:append:imx6sx-blaze = " \
    file://imx6sx-blaze.dts \
    file://0001-imx6sx-blaze-fec1-external-reference-clock.patch \
    file://no-localversion-auto.cfg \
"

# The patch is applied with git am and the device tree is copied into the tree,
# so the tree's hash changes on every build; keep it out of the kernel release,
# as toradex-kernel-localversion does, or sstate can pair a kernel with another
# build's modules.
SCMVERSION:imx6sx-blaze = "n"
DELTA_KERNEL_DEFCONFIG:append:imx6sx-blaze = " no-localversion-auto.cfg"

# The board has no device tree in the kernel tree: install it and list it in the
# Makefile so `make dtbs` builds it. A Makefile whose shape has changed under us
# would otherwise leave the dtb silently unbuilt.
do_configure:prepend:imx6sx-blaze() {
    install -m 0644 ${WORKDIR}/imx6sx-blaze.dts ${S}/arch/arm/boot/dts/nxp/imx/

    mk=${S}/arch/arm/boot/dts/nxp/imx/Makefile
    if ! grep -q "imx6sx-blaze.dtb" $mk; then
        sed -i 's|^\timx6sx-sdb.dtb \\$|\timx6sx-sdb.dtb \\\n\timx6sx-blaze.dtb \\|' $mk
        grep -q "imx6sx-blaze.dtb" $mk || bbfatal "imx6sx-blaze.dtb not listed: $mk no longer matches the expected shape"
    fi
}
