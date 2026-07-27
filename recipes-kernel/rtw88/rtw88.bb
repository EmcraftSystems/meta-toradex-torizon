# RTL8821AU USB Wi-Fi adapter driver, out of tree — RTL8821AU has no
# driver in this project's kernel
# (linux-mtk 6.6.37 predates mainline rtw88's RTL8821AU support).
#
# Sourced from lwfinger/rtw88, a maintained backport of the in-kernel
# drivers/net/wireless/realtek/rtw88 driver kept in sync with
# wireless-next — this is the same rtw8821au.c/rtw8821a_table.c a
# mainline backport would need, packaged as an externally-buildable
# tree. Its Makefile honors the KERNEL_SRC variable module.bbclass
# already sets unconditionally, so no build-system patch is required.
#
# The upstream tree's default build target compiles every rtw88 chip
# variant (rtw_8703b, rtw_8822cu, ...), not just this one; do_install
# below stages only the five modules this adapter needs (rtw8821a.c
# calls into rtw88xxa.c's exported symbols — the shared PHY/IQK code
# for the 8812a/8814a/8821a "8xxxA" chip generation — so rtw_88xxa is
# a real link-time dependency of rtw_8821a, not just rtw_core/rtw_usb),
# so the rest build but are never packaged.
SUMMARY = "Realtek RTL8821AU USB Wi-Fi driver"
LICENSE = "GPL-2.0-only | BSD-3-Clause"
LIC_FILES_CHKSUM = "file://main.c;beginline=1;endline=1;md5=04cb8411563d8726ae2273d76febc90d"

inherit module

SRC_URI = "git://github.com/lwfinger/rtw88;branch=master;protocol=https"
SRCREV = "a56bcd26e770257612a0803249cbd4095fc6feca"

S = "${WORKDIR}/git"

# module.bbclass's default do_install runs `make modules_install`, which
# this Makefile doesn't provide (only `install`, which hardcodes a host
# path and calls depmod directly rather than honoring MODLIB/D) — stage
# the five modules this adapter needs directly instead.
RTW88_MODULES = "rtw_core rtw_usb rtw_88xxa rtw_8821a rtw_8821au"

do_install() {
	install -d ${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/kernel/drivers/net/wireless/rtw88
	for mod in ${RTW88_MODULES}; do
		install -m 0644 ${B}/${mod}.ko \
			${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/kernel/drivers/net/wireless/rtw88/
	done
}

# Pull the actual split kernel-module-* packages (unversioned RPROVIDES
# virtual names, per kernel-module-split's KERNEL_MODULE_PROVIDE_VIRTUAL)
# in under this recipe's own PN, since dnf/opkg only resolve those once
# do_package has produced them.
#
# rtw_8821a also needs rtw8821a_fw.bin at probe time (rtw88's chips are
# firmware-driven — the .ko alone can't set up the radio). Rather than
# vendor a second copy of the blob from lwfinger/rtw88's own firmware/
# directory, pull it from oe-core's linux-firmware, which already
# packages it (FILES:linux-firmware-rtl8821 globs
# .../firmware/rtw88/rtw8821*.bin) under the same
# Firmware-rtlwifi_firmware license this project already accepts via
# linux-firmware-rtl8723 (see linux-firmware_%.bbappend).
RDEPENDS:${PN} = "kernel-module-rtw-core kernel-module-rtw-usb kernel-module-rtw-88xxa kernel-module-rtw-8821a kernel-module-rtw-8821au linux-firmware-rtl8821"
