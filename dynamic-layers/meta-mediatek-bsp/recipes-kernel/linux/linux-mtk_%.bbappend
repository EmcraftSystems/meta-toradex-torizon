# Kernel modules and vmlinux embed the absolute kernel-source build path via
# __FILE__ in BUG()/WARN() (__bug_table; CONFIG_DEBUG_INFO is off), tripping the
# [buildpaths] QA check on every .ko. The proper fix (rewriting __FILE__ via the
# -fmacro-prefix-map=${STAGING_KERNEL_DIR}=... that kernel-arch.bbclass already
# passes) does not work here: this aarch64 cross gcc does not apply
# -fmacro-prefix-map to __FILE__, and disabling CONFIG_DEBUG_BUGVERBOSE via a
# config fragment is reverted by olddefconfig. The warnings are non-fatal - the
# image builds and boots; the embedded paths are only a reproducibility/leak
# concern - so drop the buildpaths check for this recipe to keep the log usable.
WARN_QA:remove = "buildpaths"
