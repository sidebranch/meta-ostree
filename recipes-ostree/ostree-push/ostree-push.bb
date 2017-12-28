SUMMARY = "ostree-push.sh - Push OSTree commits to a remote repo using sshfs"

LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"
PR="0"

BBCLASSEXTEND += " native"

RDEPENDS_${PN} += " bash"

SRC_URI = " \
	file://ostree-push \
	file://COPYING \
	"
S = "${WORKDIR}"

do_install () {
	install -d ${D}/${bindir}
	install -m 0755 ostree-push ${D}/${bindir}
}
