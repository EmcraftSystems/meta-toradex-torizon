# Torizon integration overlay for the Adlink LEC-MTK-i1200 (Genio 1200 / MT8395),
# UFS boot variant. Auto-included for MACHINE=lec-mtk-i1200-ufs via the local.conf
# template, on top of the Adlink vendor machine (meta-adlink-mtk).

require common-mtk.inc

hostname:pn-base-files = "torizon-lec-mtk-i1200-ufs"

# Memory sizes with a conf-memory-<size>.dtbo in the FIT image: one per
# memory-<size>.dts in meta-adlink-mtk (recipes-kernel/dtbo/lec-mtk-i1200/,
# patched by this layer's dtbo_%.bbappend).
# Add a size here only together with its overlay: booting a conf the FIT image
# does not contain fails the boot, and that cannot be recovered remotely.
MEMORY_OVERLAYS ?= "2G 4G 8G"

# Apply the memory overlay for the module's SKU. U-Boot's board code reads the
# SKU pins and sets fitconf_memory to its conf-memory-<size>.dtbo, or deletes
# it for an unknown SKU, which leaves the 4 GiB default. The FIT image carries a
# configuration only for the sizes in MEMORY_OVERLAYS. Only test and env are
# used, so the line passes the U-Boot command whitelist of signed builds.
UENV_EXTRA_CONFIGS:append = " ; if test -n "${fitconf_memory}" ; then env set fitconf_fdt_overlays "${fitconf_fdt_overlays}\#${fitconf_memory}" ; fi"

# Signed builds with the U-Boot hardening boot with the overlay that carries the
# required kernel command line (the dtbo recipe builds it).
FITCONF_FDT_OVERLAYS:append:tdx-signed = "${@'#conf-%s.dtbo' % d.getVar('TDX_SECBOOT_KARGS_OVERLAY') if d.getVar('TDX_UBOOT_HARDENING_ENABLE') == '1' else ''}"

# Kernel command line for the OSTree / OTA rootfs. Console is uart0 (ttyS0) at
# 921600, matching the board DTS stdout-path and U-Boot.
#
# Overrides (not appends to) torizon.bbclass's shared OSTREE_KERNEL_ARGS
# default: routes console output to fbcon and disables the Plymouth splash so
# it doesn't obscure the login prompt.
OSTREE_KERNEL_ARGS:sota:lec-mtk1200 = "logo.nologo vt.global_cursor_default=0 plymouth.enable=0 nosplash fbcon=map:0 console=ttyS0,921600 console=tty1 earlycon root=LABEL=otaroot rootfstype=ext4 rootwait"

# The board carries a TPM2.0.
DISTRO_FEATURES:append = " tpm2"
# tpm2-tools comes from meta-tpm, which the manifest does not include.
IMAGE_INSTALL:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'tpm-layer', ' tpm2-tools', '', d)}"

# Build and deploy host-side genio2img/img2genio torizoncore-builder
# converters alongside the image.
EXTRA_IMAGEDEPENDS:append = " genio2img-tools"

# tdx-encrypted builds: the encrypted data partition is created on first boot on
# the on-module UFS, where resize-helper would otherwise grow the rootfs over the
# whole disk, and container storage moves onto it.
DATA_PARTITION_ID_PATH = "platform-11270000.ufshci-scsi-*"
RESIZE_HELPER:tdx-encrypted = ""
IMAGE_INSTALL:append:tdx-encrypted = " data-partition docker-encdata"

# RTL8821AU USB Wi-Fi driver (recipes-kernel/rtw88); named by PN since
# only the kernel recipe declares PACKAGES_DYNAMIC for kernel-module-*.
IMAGE_INSTALL:append = " rtw88"

# Socket-tied naming for USB wireless interfaces (recipes-bsp/usb-wifi-naming);
# the name must be fixed to the SMARC socket, identical on every unit.
IMAGE_INSTALL:append = " usb-wifi-naming"

# Firmware for the on-module 88W8997 Wi-Fi/Bluetooth radio; mwifiex picks the
# file from the module's host-interface strap.
IMAGE_INSTALL:append = " linux-firmware-pcie8997"
