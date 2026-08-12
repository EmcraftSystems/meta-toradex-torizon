FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# meta-virtualization's linux-%.bbappend supplies the container kernel features
# only for recipes carrying kmeta metadata: for any other kernel it computes
# KERNEL_META_TYPE = "none" and `include`s linux-none_<ver>_virtualization.inc,
# which does not exist -- and a bitbake include of a missing file is a silent
# no-op. This recipe has no kmeta, so it reaches the image with none of them.
#
# Scoped to the overrides that select imx_v7_defconfig: imx_v8_defconfig already
# carries this set, at values this fragment would redefine rather than add to.
SRC_URI:append:mx6-generic-bsp = " file://torizon-container.cfg"
SRC_URI:append:mx7-generic-bsp = " file://torizon-container.cfg"
