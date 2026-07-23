# Torizon integration overlay for the Adlink LEC-MTK-i1200 (Genio 1200 / MT8395),
# UFS boot variant. Auto-included for MACHINE=lec-mtk-i1200-ufs via the local.conf
# template, on top of the Adlink vendor machine (meta-adlink-mtk).

require common-mtk.inc

hostname:pn-base-files = "torizon-lec-mtk-i1200-ufs"

# Kernel command line for the OSTree / OTA rootfs. Console is uart0 (ttyS0) at
# 921600, matching the board DTS stdout-path and U-Boot.
#
# Overrides (rather than appends to) torizon.bbclass's shared default -
# "... plymouth.ignore-serial-consoles splash fbcon=map:3 ..." - replacing
# Plymouth's splash with plymouth.enable=0 fbcon=map:0 console=tty1, to
# isolate whether the display fault is tied to the Plymouth-to-fbcon handoff.
# Folds in the console/rootfs args below into one override so there's no
# duplication with the old :append:sota form.
OSTREE_KERNEL_ARGS:sota:lec-mtk1200 = "logo.nologo vt.global_cursor_default=0 plymouth.enable=0 fbcon=map:0 console=ttyS0,921600 console=tty1 earlycon root=LABEL=otaroot rootfstype=ext4 rootwait"

# The board carries a TPM2.0.
DISTRO_FEATURES:append = " tpm2"
