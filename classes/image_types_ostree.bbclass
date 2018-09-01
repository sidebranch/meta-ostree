# OSTree deployment

inherit image

export OSTREE_REPO
export OSTREE_BRANCHNAME
export OSTREE_INITRAMFS_IMAGE

do_image_ostree[depends] = "ostree-native:do_populate_sysroot \
                        openssl-native:do_populate_sysroot \
                        coreutils-native:do_populate_sysroot \
                        virtual/kernel:do_deploy"

# if an ostree initramfs is used, also depend on its completion
python __anonymous () {
    ostree_image = d.getVar('OSTREE_INITRAMFS_IMAGE')
    initramfs_image = d.getVar('INITRAMFS_IMAGE')
    bundled = d.getVar('INITRAMFS_IMAGE_BUNDLE')
    if ostree_image and not bundled:
        d.appendVarFlag('do_image_ostree', 'depends', ' ${OSTREE_INITRAMFS_IMAGE}:do_image_complete')
}

# if NO ostree initramfs is used, the root filesystem should make the OSTree switch
python __anonymous () {
    image = d.getVar('OSTREE_INITRAMFS_IMAGE')

    if not image:
        d.appendVar("IMAGE_INSTALL", " ostree-switchroot")
        d.appendVar("RDEPENDS", " ostree-switchroot")
}

RAMDISK_EXT ?= ".${OSTREE_INITRAMFS_FSTYPES}"

OSTREE_KERNEL ??= "${KERNEL_IMAGETYPE}"

export SYSTEMD_USED = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', '', d)}"

IMAGE_CMD_ostree () {
    if [ -z "$OSTREE_REPO" ]; then
        bbfatal "OSTREE_REPO should be set in your local.conf"
    fi

    if [ -z "$OSTREE_BRANCHNAME" ]; then
        bbfatal "OSTREE_BRANCHNAME should be set in your local.conf"
    fi

    OSTREE_ROOTFS=`mktemp -du ${WORKDIR}/ostree-root-XXXXX`
    cp -a ${IMAGE_ROOTFS} ${OSTREE_ROOTFS}
    chmod a+rx ${OSTREE_ROOTFS}
    sync

    cd ${OSTREE_ROOTFS}

    # Create sysroot directory to which physical sysroot will be mounted
    mkdir sysroot
    ln -sf sysroot/ostree ostree

    rm -rf tmp/*
    ln -sf sysroot/tmp tmp

    mkdir -p usr/rootdirs

    mv etc usr/
    # Implement UsrMove
    dirs="bin sbin lib"

    for dir in ${dirs} ; do
        if [ -d ${dir} ] && [ ! -L ${dir} ] ; then
            bbwarn "Moving ${dir} to /usr/rootdirs/ to implement usrmerge"
            mv ${dir} usr/rootdirs/
            rm -rf ${dir}
            ln -sf usr/rootdirs/${dir} ${dir}
        fi
    done

    if [ -n "$SYSTEMD_USED" ]; then
        mkdir -p usr/etc/tmpfiles.d
        tmpfiles_conf=usr/etc/tmpfiles.d/00ostree-tmpfiles.conf
        echo "d /var/rootdirs 0755 root root -" >>${tmpfiles_conf}
        echo "L /var/rootdirs/home - - - - /sysroot/home" >>${tmpfiles_conf}
    else
        mkdir -p usr/etc/init.d
        mkdir -p usr/etc/rcS.d
        tmpfiles_conf=usr/etc/init.d/tmpfiles.sh
        echo '#!/bin/sh' > ${tmpfiles_conf}
        echo "mkdir -p /var/rootdirs; chmod 755 /var/rootdirs" >> ${tmpfiles_conf}
        echo "ln -sf /sysroot/home /var/rootdirs/home" >> ${tmpfiles_conf}

        ln -s ../init.d/tmpfiles.sh usr/etc/rcS.d/S20tmpfiles.sh
    fi

    # Preserve OSTREE_BRANCHNAME for future information
    mkdir -p usr/share/sota/
    echo -n "${OSTREE_BRANCHNAME}" > usr/share/sota/branchname

    # Preserve data in /home to be later copied to /sysroot/home by sysroot
    # generating procedure
    mkdir -p usr/homedirs
    if [ -d "home" ] && [ ! -L "home" ]; then
        bbwarn "Moving home to /usr/homedirs/ to implement usrmerge"
        mv home usr/homedirs/home
        # @TODO this seems bug? var instead of usr?
        ln -sf var/rootdirs/home home
    fi

    # Move persistent directories to /var
    dirs="opt mnt media srv"

    for dir in ${dirs}; do
        if [ -d ${dir} ] && [ ! -L ${dir} ]; then
            if [ "$(ls -A $dir)" ]; then
                bbwarn "Data in /$dir directory is not preserved by OSTree. Consider moving it under /usr"
            fi

            if [ -n "$SYSTEMD_USED" ]; then
                echo "d /var/rootdirs/${dir} 0755 root root -" >>${tmpfiles_conf}
            else
                echo "mkdir -p /var/rootdirs/${dir}; chown 755 /var/rootdirs/${dir}" >>${tmpfiles_conf}
            fi
            rm -rf ${dir}
            ln -sf var/rootdirs/${dir} ${dir}
        fi
    done

    if [ -d root ] && [ ! -L root ]; then
        if [ "$(ls -A root)" ]; then
            bberror "Data in /root directory is not preserved by OSTree."
            exit 1
        fi

        if [ -n "$SYSTEMD_USED" ]; then
            echo "d /var/roothome 0755 root root -" >>${tmpfiles_conf}
        else
            echo "mkdir -p /var/roothome; chown 755 /var/roothome" >>${tmpfiles_conf}
        fi

        rm -rf root
        ln -sf var/roothome root
    fi

    # Creating boot directories is required for "ostree admin deploy"

    mkdir -p boot/loader.0
    mkdir -p boot/loader.1
    ln -sf boot/loader.0 boot/loader

    checksum=`sha256sum ${DEPLOY_DIR_IMAGE}/${OSTREE_KERNEL} | cut -f 1 -d " "`
    bbwarn "${DEPLOY_DIR_IMAGE}/${OSTREE_KERNEL} checksum is ${checksum}"

    cp ${DEPLOY_DIR_IMAGE}/${OSTREE_KERNEL} boot/vmlinuz-${checksum}

    #bbwarn "OSTREE_INITRAMFS_IMAGE=${OSTREE_INITRAMFS_IMAGE}"

    # initramfs for ostree switching is configured, and not bundled in kernel image?
    if test -z "$OSTREE_INITRAMFS_IMAGE"; then
        bbwarn "OSTREE_INITRAMFS_IMAGE is not set."
    fi

    if [ ! -z "$OSTREE_INITRAMFS_IMAGE" ]; then
        if [ ! -n "${INITRAMFS_IMAGE_BUNDLE}" ]; then
            bbwarn "OSTree: copying ${OSTREE_INITRAMFS_IMAGE}${RAMDISK_EXT} to /boot/initramfs-${checksum}"       
            cp ${DEPLOY_DIR_IMAGE}/${OSTREE_INITRAMFS_IMAGE}${RAMDISK_EXT} boot/initramfs-${checksum}
        else
	    bbwarn "OSTree: INITRAMFS_IMAGE_BUNDLE is set; creating fake (empty) /boot/initramfs-${checksum}."
            touch boot/initramfs-${checksum}
        fi
    else
        bbwarn "OSTree system without initramfs because OSTREE_INITRAMFS_IMAGE is not set."
    fi

    # Copy image manifest
    # cat ${IMAGE_MANIFEST} | cut -d " " -f1,3 > usr/package.manifest

    cd ${WORKDIR}

    # Create a tarball that can be then commited to OSTree repo
    OSTREE_TAR=${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ostree.tar
    ${IMAGE_CMD_TAR} -C ${OSTREE_ROOTFS} --xattrs --xattrs-include='*' -cf ${OSTREE_TAR} .
    #sync

    rm -f ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.rootfs.ostree.tar
    #ln -s ${IMAGE_NAME}.rootfs.ostree.tar ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.rootfs.ostree.tar

    if [ ! -d ${OSTREE_REPO} ]; then
        ostree --repo=${OSTREE_REPO} init --mode=archive-z2
    fi

    # Commit the result
    ostree --repo=${OSTREE_REPO} commit \
           --tree=dir=${OSTREE_ROOTFS} \
           --skip-if-unchanged \
           --branch=${OSTREE_BRANCHNAME} \
           --subject="yocto-build: ${IMAGE_NAME}" \
           --body="Build-meta-rev: `git describe --tags --dirty --always`\nBuildhost: `uname -a`"
    rm -rf ${OSTREE_ROOTFS}

    # Push to the server
    # ostree-push -v --debug --repo=${OSTREE_REPO} ostree-push@127.0.0.1:repo_build/
}
