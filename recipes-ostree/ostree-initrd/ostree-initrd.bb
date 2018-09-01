SUMMARY = "Extremely basic live image init script"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = "file://init.sh"

PV = "4"

do_install () {
    install -dm 0755 ${D}/dev
    install -dm 0755 ${D}/dev/pts
    install -dm 0755 ${D}/home
    install -dm 0755 ${D}/home/root
    install -dm 0755 ${D}/proc
    install -dm 0755 ${D}/sys
    install -D -m 0755 ${WORKDIR}/init.sh ${D}${sysconfdir}/init.d/ostree
    touch ${D}${sysconfdir}/fstab
}

FILES_${PN} = "${sysconfdir} /dev /proc /sys /home"

INITSCRIPT_NAME = "ostree"
INITSCRIPT_PARAMS = "defaults"

inherit update-rc.d allarch

#ERROR_QA_remove = "usrmerge"
