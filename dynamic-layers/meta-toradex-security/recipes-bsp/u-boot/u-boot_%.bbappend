# Secure boot features of meta-toradex-security (FIT signature check, U-Boot
# hardening) for the MediaTek Genio U-Boot; that layer only hooks Toradex's own
# U-Boot recipes.
require ${@'recipes-bsp/u-boot/u-boot-sec-features.inc' if 'lec-mtk1200' in d.getVar('OVERRIDES').split(':') else ''}

FILESEXTRAPATHS:prepend:lec-mtk1200 := "${THISDIR}/files:"

# The upstream patch flavour, with the patches that do not apply to the MediaTek
# U-Boot 2022.10 replaced by ported copies. The fastboot and fuse command
# protections are left out: this U-Boot is not flashed over fastboot and has no
# fuse command, so TDX_UBOOT_HARDENING_ENABLE_FB_PROT must stay 0.
TDX_UBOOT_SECBOOT_PATCHES:lec-mtk1200 = " \
    ${TDX_UBOOT_SECBOOT_PATCHES_COMMON} \
    file://0001-lmb-prevent-alloc-overlap-with-reserved-regions-upst.patch \
    file://0001-toradex-integrate-shared-secboot-module-mtk.patch \
    file://0001-command-add-the-cmd_arg-helpers.patch \
"
TDX_UBOOT_HARDENING_PATCHES:lec-mtk1200 = " \
    ${TDX_UBOOT_HARDENING_PATCHES_COMMON} \
    file://0001-toradex-integrate-command-whitelisting-mtk.patch \
    file://0002-toradex-integrate-bootm-protection-mtk.patch \
    file://0003-toradex-integrate-CLI-access-protection-mtk.patch \
    file://0004-toradex-integrate-bootargs-protection-mtk.patch \
    file://0005-toradex-integrate-load-protection-upstream.patch \
    file://0006-toradex-integrate-cp-protection-upstream.patch \
    file://0010-toradex-cmd-setexpr-integrate-protections-upstream.patch \
    file://0011-toradex-whitelist-add-the-scsi-command.patch \
"

# The hardening refuses any standard-boot method but the script one;
# disable-bootmeths.cfg uses the later U-Boot names for these two.
SRC_URI:append:lec-mtk1200:tdx-signed = "${@' file://disable-bootmeths-mtk.cfg' if d.getVar('TDX_UBOOT_HARDENING_ENABLE') == '1' else ''}"
