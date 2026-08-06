# NXP i.MX6SoloX SABRE-SD — Torizon machine glue.
#
# The machine itself comes from meta-freescale, on its mainline BSP default.
# This file carries only what Torizon needs on top, and is pulled in by
# conf/template/local.conf's `include conf/machine/include/${MACHINE}.inc`.

# The kernel builds its device trees from KERNEL_DEVICETREE, so there is no
# virtual/dtb provider. ostree-kernel-initramfs_%.bbappend keys an optional
# virtual/dtb dependency off this variable, and leaving it unset breaks the
# task-graph resolve rather than skipping the dependency. Every other
# non-Toradex machine here sets it empty for the same reason.
PREFERRED_PROVIDER_virtual/dtb = ""
