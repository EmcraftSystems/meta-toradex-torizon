# The base recipe gates bl_actions.sh/common_actions.sh install on
# BL_UPDATE_SUPPORT, but writes the "<machine>-bootloader" ECU into
# secondaries.json unconditionally - left a ghost entry when the handler
# script is disabled (imx6sxsabresd.inc). Strip it so aktualizr never
# registers an ECU it cannot act through.
#
# fuse_actions.sh (installed unconditionally, for the still-enabled
# fuse-programming secondary) also sources common_actions.sh, so disabling
# bootloader-update support silently broke fusing ("common_actions.sh: No
# such file or directory", confirmed in the journal on hardware). Install
# it here so the two secondaries don't share a fate they don't share a
# purpose with.
do_install:append:imx6sxsabresd () {
    if [ "${BL_UPDATE_SUPPORT}" != "1" ]; then
        jq 'del(.["torizon-generic"][] | select(.ecu_hardware_id == "${MACHINE}-bootloader"))' \
            ${D}${libdir}/sota/secondaries.json > ${WORKDIR}/secondaries.json.filtered
        install -m 0644 ${WORKDIR}/secondaries.json.filtered ${D}${libdir}/sota/secondaries.json

        install -d ${D}${bindir}
        install -m 0644 ${WORKDIR}/common_actions.sh ${D}${bindir}/common_actions.sh
    fi
}
