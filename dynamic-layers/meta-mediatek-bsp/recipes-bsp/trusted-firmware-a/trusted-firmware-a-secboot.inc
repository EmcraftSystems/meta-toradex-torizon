# Signed builds: BL2 authenticates the firmware image package against the hash
# of SECURE_BOOT_ROT_KEY compiled into it, independently of the eFuses. These
# are the options MediaTek's "secure-boot" distro feature sets; that feature is
# left off because it also drops the U-Boot environment that the update
# rollback needs.
TFA_MBEDTLS:tdx-signed = "1"
EXTRA_OEMAKE:append:tdx-signed = " ${TFA_SECURE_BOOT_OPTION}"
