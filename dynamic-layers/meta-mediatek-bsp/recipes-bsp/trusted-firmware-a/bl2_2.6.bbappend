require trusted-firmware-a-secboot.inc

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# A FIP slot that fails to load or authenticate falls back without a power cycle.
SRC_URI:append:lec-mtk1200 = " \
	file://0001-mt8195-reset-on-a-BL2-error-or-panic-with-A-B-boot.patch \
	file://0002-bl_common-zero-a-rejected-image-with-zeromem.patch \
"
