python __anonymous() {
    if bb.utils.contains('DISTRO_FEATURES', 'sota', True, False, d):
        d.appendVarFlag("do_image_wic", "depends", " %s:do_image_otaimg" % d.getVar("IMAGE_BASENAME", True))
}

OVERRIDES .= "${@bb.utils.contains('DISTRO_FEATURES', 'sota', ':sota', '', d)}"

IMAGE_INSTALL_append_sota = " ostree os-release"
IMAGE_CLASSES += "image_types_ostree image_types_ota"

IMAGE_FSTYPES += "${@bb.utils.contains('DISTRO_FEATURES', 'sota', 'otaimg', ' ', d)}"

#PACKAGECONFIG_append_pn-curl = "${@bb.utils.contains('SOTA_CLIENT_FEATURES', 'hsm', " ssl", " ", d)}"
#PACKAGECONFIG_remove_pn-curl = "${@bb.utils.contains('SOTA_CLIENT_FEATURES', 'hsm', " gnutls", " ", d)}"
#WKS_FILE_sota ?= "sdimage-sota.wks"

#EXTRA_IMAGEDEPENDS_append_sota = " parted-native mtools-native dosfstools-native"

#OSTREE_INITRAMFS_FSTYPES ??= "${@oe.utils.ifelse(d.getVar('OSTREE_BOOTLOADER', True) == 'u-boot', 'ext4.gz.u-boot', 'ext4.gz')}"

# @TODO multiple seems impossible (for example adding tar for easier inspection -> breaks)
OSTREE_INITRAMFS_FSTYPES ?= "cpio"

# Please redefine OSTREE_REPO in order to have a persistent OSTree repo
OSTREE_REPO ?= "${DEPLOY_DIR_IMAGE}/ostree_repo"
# For UPTANE operation, OSTREE_BRANCHNAME must start with "${MACHINE}-"
OSTREE_BRANCHNAME ?= "${MACHINE}"
OSTREE_OSNAME ?= "poky"
#OSTREE_INITRAMFS_IMAGE ?= "initramfs-ostree-image"

OSTREE_BOOTLOADER ?= "u-boot"

#SOTA_MACHINE ??="none"
#SOTA_MACHINE_raspberrypi2 ?= "raspberrypi"
#SOTA_MACHINE_raspberrypi3 ?= "raspberrypi"
#SOTA_MACHINE_qemux86-64 ?= "qemux86-64"
#SOTA_MACHINE_imx7d-phyboard-zeta-001 ?= "imx7-phytec-zeta"
#SOTA_MACHINE_imx7d-phyboard-zeta-002 ?= "imx7-phytec-zeta"
#
#inherit sota_${SOTA_MACHINE}
