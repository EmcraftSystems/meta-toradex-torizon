# virtual/dtb on MediaTek is this recipe, not toradex-devicetree: deploy
# overlays.txt here, with toradex-devicetree.bbclass's boot-overlay contract.
TEZI_EXTERNAL_KERNEL_DEVICETREE_BOOT ??= ""

do_deploy:append () {
    overlays=
    for dtbo in ${TEZI_EXTERNAL_KERNEL_DEVICETREE_BOOT}; do
        if [ ! -e ${DEPLOYDIR}/devicetree/$dtbo ]; then
            bbfatal "$dtbo is not provided by ${PN}, please make sure it's in its SRC_URI."
        fi
        overlays="$overlays $dtbo"
    done

    echo "fdt_overlays=$(echo $overlays)" > ${DEPLOYDIR}/overlays.txt
}

# Signed builds with the U-Boot hardening: the fixed part of the kernel command
# line, as an overlay in the FIT image that U-Boot checks bootargs against. The
# devicetree class compiles every .dts in its source directory.
SECBOOT_KARGS = "${@'1' if 'tdx-signed' in d.getVar('OVERRIDES').split(':') and d.getVar('TDX_UBOOT_HARDENING_ENABLE') == '1' else ''}"

do_configure:append () {
    if [ -n "${SECBOOT_KARGS}" ]; then
        [ -n "${TDX_SECBOOT_REQUIRED_BOOTARGS}" ] || bbfatal "TDX_SECBOOT_REQUIRED_BOOTARGS is empty"
        cat > ${S}/${TDX_SECBOOT_KARGS_OVERLAY}.dts <<EOT
/dts-v1/;
/plugin/;

&{/} {
	chosen {
		toradex,secure-boot {
			required-bootargs = "${TDX_SECBOOT_REQUIRED_BOOTARGS}";
		};
	};
};
EOT
    fi
}
