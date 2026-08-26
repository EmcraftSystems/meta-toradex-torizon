# The offline-update mount-path convention (torizon volume label) is a
# project-specific choice, not one every machine sharing this recipe
# should inherit.
RDEPENDS:${PN}:append:imx6sxsabresd = " aktualizr-offline-updates"
