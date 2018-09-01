SUMMARY = "Tool for managing bootable, immutable, versioned filesystem trees"
LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://COPYING;md5=5f30f0716dfdd0d91eb439ebec522ec2"

inherit autotools-brokensep pkgconfig systemd gobject-introspection

INHERIT_remove_class-native = "systemd"

SRC_URI = "\
https://github.com/ostreedev/ostree/releases/download/v${PV}/libostree-${PV}.tar.xz \
file://missing-TEMP_FAILURE_RETRY.patch \
file://loff_t-not-defined.patch \
"

S = "${WORKDIR}/libostree-${PV}"

BBCLASSEXTEND = "native"

#DEPENDS += "attr libarchive glib-2.0 pkgconfig gpgme libgsystem fuse libsoup-2.4 e2fsprogs gtk-doc-native curl xz"
#DEPENDS += "attr libarchive glib-2.0 pkgconfig gpgme fuse libsoup-2.4 e2fsprogs gtk-doc-native curl xz"
#DEPENDS += "attr libarchive glib-2.0 pkgconfig gpgme fuse libsoup-2.4 e2fsprogs curl xz"
#
DEPENDS += "attr libarchive glib-2.0 pkgconfig gpgme fuse e2fsprogs curl xz"

DEPENDS_append_class-native = " libarchive"

DEPENDS_append = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', ' systemd', '', d)}"
DEPENDS_remove_class-native = "systemd-native"

RDEPENDS_${PN} = "util-linux-libuuid util-linux-libblkid util-linux-libmount libcap"

# for tests only
#RDEPENDS_${PN} += "bash"

# works
#EXTRA_OECONF = "--with-static-compiler='${CC}' --without-libarchive --disable-gtk-doc --disable-gtk-doc-html --disable-gtk-doc-pdf --disable-man --with-smack --with-builtin-grub2-mkconfig --with-curl --without-soup --disable-glibtest --enable-introspection=no --without-avahi"
EXTRA_OECONF = "--without-libarchive --disable-gtk-doc --disable-gtk-doc-html --disable-gtk-doc-pdf --disable-man --with-smack --with-builtin-grub2-mkconfig --with-curl --without-soup --disable-glibtest --enable-introspection=no --without-avahi"
EXTRA_OECONF_append_class-native = " --enable-wrpseudo-compat --with-libarchive"
EXTRA_OECONF_remove_class-native = " --without-libarchive"

# if no ostree initramfs is used, the switch runs as init PID #1, but cannot load libraries
python __anonymous () {
    image = d.getVar('OSTREE_INITRAMFS_IMAGE')
    if not image:
        d.appendVar("EXTRA_OECONF", " --with-static-compiler='${CC}'")
}


# Do not generate documentation
#EXTRA_OECONF =              "--disable-gtk-doc --disable-gtk-doc-html --disable-gtk-doc-pdf --disable-man"
#EXTRA_OECONF_class-native = "--disable-gtk-doc --disable-gtk-doc-html --disable-gtk-doc-pdf --disable-man"
#
# Target: static ostree-switch executable, no archive support, no SMACK, no GRUB, use curl instead of soup
#EXTRA_OECONF +=  "--with-static-compiler --without-libarchive --without-smack --without-builtin-grub2-mkconfig --with-curl --without-soup"
#
# Host: Enabled both archive support and pseudo support required under OpenEmbedded/Yocto
#EXTRA_OECONF_class-native += "--with-libarchive --without-smack --without-builtin-grub2-mkconfig --with-curl --without-soup --enable-wrpseudo-compat"
#

# Path to ${prefix}/lib/ostree/ostree-grub-generator is hardcoded on the
#  do_configure stage so we do depend on it
SYSROOT_DIR = "${STAGING_DIR_TARGET}"
SYSROOT_DIR_class-native = "${STAGING_DIR_NATIVE}"
do_configure[vardeps] += "SYSROOT_DIR"

SYSTEMD_REQUIRED = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}"
SYSTEMD_REQUIRED_class-native = ""

SYSTEMD_SERVICE_${PN} = "ostree-prepare-root.service ostree-remount.service"
SYSTEMD_SERVICE_${PN}_class-native = ""

PACKAGECONFIG ??= "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd', '', d)}"
PACKAGECONFIG_class-native = ""
PACKAGECONFIG[systemd] = "--with-systemdsystemunitdir=${systemd_unitdir}/system/ --with-dracut"

FILES_${PN} += "${libdir}/ostree/ ${libdir}/ostbuild"

export STAGING_INCDIR
export STAGING_LIBDIR

do_configure() {
 unset docdir
 NOCONFIGURE=1 ./autogen.sh
 oe_runconf
}

do_compile_prepend() {
 export BUILD_SYS="${BUILD_SYS}"
 export HOST_SYS="${HOST_SYS}"
}

export SYSTEMD_REQUIRED

do_install_append() {
 if [ -n ${SYSTEMD_REQUIRED} ]; then
  install -p -D ${S}/src/boot/ostree-prepare-root.service ${D}${systemd_unitdir}/system/ostree-prepare-root.service
  install -p -D ${S}/src/boot/ostree-remount.service ${D}${systemd_unitdir}/system/ostree-remount.service
 fi
 rm -rf ${D}${datadir}/bash-completion
}

do_install_append_class-native() {
	create_wrapper ${D}${bindir}/ostree OSTREE_GRUB2_EXEC="${STAGING_LIBDIR_NATIVE}/ostree/ostree-grub-generator"
}


FILES_${PN} += " \
    ${@'${systemd_unitdir}/system/' if d.getVar('SYSTEMD_REQUIRED', True) else ''} \
    ${@'${libdir}/dracut/modules.d/98ostree/module-setup.sh' if d.getVar('SYSTEMD_REQUIRED', True) else ''} \
    ${datadir}/gir-1.0 \
    ${datadir}/gir-1.0/OSTree-1.0.gir \
    ${libdir}/girepository-1.0 \
    ${libdir}/girepository-1.0/OSTree-1.0.typelib \
    ${libdir}/tmpfiles.d/ostree-tmpfiles.conf \
    ${systemd_unitdir}/system-generators/ostree-system-generator \
"

#
#    ${datadir}/bash-completion/completions/ostree \
#

PACKAGES =+ "${PN}-switchroot"

FILES_${PN}-switchroot = "${libdir}/ostree/ostree-prepare-root"
RDEPENDS_${PN}-switchroot = ""
DEPENDS_remove_class-native = "systemd-native"

do_workaround_usrmerge_recipe_sysroot () {
    ln -snf usr/lib ${RECIPE_SYSROOT}/lib
}

addtask do_workaround_usrmerge_recipe_sysroot after do_prepare_recipe_sysroot before do_configure
