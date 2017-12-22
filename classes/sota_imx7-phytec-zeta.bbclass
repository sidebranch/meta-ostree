#IMAGE_CLASSES += "${@bb.utils.contains('DISTRO_FEATURES', 'sota', 'image_types_uboot', '', d)}"
#IMAGE_FSTYPES += "${@bb.utils.contains('DISTRO_FEATURES', 'sota', 'rpi-sdimg-ota.xz', 'rpi-sdimg.xz', d)}"

# Undo part of sota.bbclass again; keep ostreepush removed
IMAGE_FSTYPES_remove = "${@bb.utils.contains('DISTRO_FEATURES', 'sota', 'ostreepush', '', d)}"

#KERNEL_IMAGETYPE_sota = "uImage"

# This is already set elsewhere and does not depend on SOTA
#PREFERRED_PROVIDER_virtual/bootloader_sota ?= "u-boot-phytec"
#UBOOT_MACHINE_imx7d-phyboard-zeta-001_sota ?= "imx7d-phyboard-zeta-001"

OSTREE_BOOTLOADER ?= "u-boot"
