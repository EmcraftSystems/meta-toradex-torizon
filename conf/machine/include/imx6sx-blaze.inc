require common-imx6.inc

# The bootloader lives in the eMMC boot0 hardware partition, so this image has
# no bootloader partition. Set after the require, which assigns with a hard =.
WKS_FILE:sota = "torizon-imx6sx-blaze-sota.wks"

TORIZON_TTY_DEVICE = "ttymxc2,115200"

EXTRA_IMAGEDEPENDS:append = " torizon-uuu"

# packagegroup-base-wifi carries no TI firmware, so the driver cannot boot the
# chip without linux-firmware-wl18xx.
#
# wl18xx-conf carries this module's PHY calibration. Without it the driver warns
# and falls back to built-in defaults that are not this module's.
MACHINE_EXTRA_RRECOMMENDS:append = " linux-firmware-wl18xx wl18xx-conf"
