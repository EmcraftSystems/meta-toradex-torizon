# Reuse one persistent TPM primary key instead of adding one on every re-flash.
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append:lec-mtk1200 = " file://0001-tdx-enc-reuse-one-persistent-TPM-primary-key.patch;patchdir=${WORKDIR}"

TDX_ENC_TPM_HANDLE ?= "0x81000000"

do_install:append:lec-mtk1200() {
    sed -i 's|@@TDX_ENC_TPM_HANDLE@@|${TDX_ENC_TPM_HANDLE}|g' ${D}${sbindir}/tdx-enc.sh
}
