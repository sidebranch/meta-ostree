# OSTree initramfs image.
DESCRIPTION = "OSTree initramfs image"

USE_DEVFS = "0"

PACKAGE_INSTALL = "ostree-switchroot ostree-initrd busybox base-passwd ${ROOTFS_BOOTSTRAP_INSTALL}"

SYSTEMD_DEFAULT_TARGET = "initrd.target"

# Do not pollute the initrd image with rootfs features
IMAGE_FEATURES = "debug-tweaks"

export IMAGE_BASENAME = "initramfs-ostree-image"
IMAGE_LINGUAS = ""

LICENSE = "MIT"

IMAGE_FSTYPES = "${OSTREE_INITRAMFS_FSTYPES}"
IMAGE_NAME_SUFFIX = ""
inherit core-image

# this doesn't seem to work
DISTRO_FEATURES = ""

IMAGE_ROOTFS_SIZE = "8192"

# Users will often ask for extra space in their rootfs by setting this
# globally.  Since this is a initramfs, we don't want to make it bigger
IMAGE_ROOTFS_EXTRA_SPACE = "0"
IMAGE_OVERHEAD_FACTOR = "1.0"

BAD_RECOMMENDATIONS += "busybox-syslog"

