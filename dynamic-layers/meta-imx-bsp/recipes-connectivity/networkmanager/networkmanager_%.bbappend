# meta-imx installs /etc/systemd/network/99-default.link as a symlink to
# /dev/null -- "Disable the assignment of the fixed network interface name" --
# so udev computes ID_NET_NAME_ONBOARD=end0 but never applies it, and the kernel
# names eth0/eth1 survive. The generated profiles have to match.
#
# This lives here rather than in common-imx6.inc because the name follows the
# BSP, not the branch: the file parses only when meta-imx is in the build, so a
# machine keeps end0/end1 until its own BSP moves, whichever ticket merges first.
#
# The same key common-imx6.inc uses, parsed later: a bbappend is read after the
# machine include, so this assignment replaces it. A machine-scoped
# NET_NAME:common-imx6 would work too -- OVERRIDES lists pn-${PN} ahead of
# ${MACHINEOVERRIDES} and the later entry wins -- but matching the key keeps the
# two assignments legible as one pair.
NET_NAME:pn-networkmanager = "eth"
