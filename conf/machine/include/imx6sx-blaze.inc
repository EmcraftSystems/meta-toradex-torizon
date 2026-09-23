require common-imx6.inc

# The bootloader lives in the eMMC boot0 hardware partition, so this image has
# no bootloader partition. Set after the require, which assigns with a hard =.
WKS_FILE:sota = "torizon-imx6sx-blaze-sota.wks"

TORIZON_TTY_DEVICE = "ttymxc2,115200"

EXTRA_IMAGEDEPENDS:append = " torizon-uuu"

# Common Torizon disables bootloader OTA for every machine; this board can
# carry it -- the bootloader is a bare u-boot.imx in an eMMC boot partition.
UBOOT_BINARY_OTA_IGNORE:imx6sx-blaze = "0"
UBOOT_BINARY_OTA:imx6sx-blaze = "u-boot.imx"

# packagegroup-base-wifi carries no TI firmware, so the driver cannot boot the
# chip without linux-firmware-wl18xx.
#
# wl18xx-conf carries this module's PHY calibration. Without it the driver warns
# and falls back to built-in defaults that are not this module's.
MACHINE_EXTRA_RRECOMMENDS:append = " linux-firmware-wl18xx wl18xx-conf"
