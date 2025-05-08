#!/bin/bash
source "config"

# constants
DEBIAN_VERSION="bookworm" # bookworm:12
DEBIAN_ARCH="amd64"
IMAGE_SIZE=1000 # size ofimage in MB

# TODO: check GNU/Linux distribution

# TODO: check ROOTFS - must be something except / or empty

# check if folders exist
[ ! -d ${ROOTFS} ] && mkdir ${ROOTFS} &>>/dev/null
[ ! -d ${IMAGES} ] && mkdir ${IMAGES} &>>/dev/null

######################################
########## BUILD ROOTFS ##############
######################################

# debootstrap to rootfs folder
debootstrap --arch ${DEBIAN_ARCH} ${DEBIAN_VERSION} ${ROOTFS} https://deb.debian.org/debian

# update repository source lists
sed -i 's/main$/main contrib non-free-firmware/g' ${ROOTFS}/etc/apt/sources.list

# add development stuff - just for development (pass: x)
chroot ${ROOTFS} useradd -m -s /bin/bash -p '$y$j9T$omjeV.F9RBuRT6uiB8N8L0$zPqVN0qa3Hz/fAvqK0k8.oA4BqDmg2zOXjfvO2TFPN5' development
chroot ${ROOTFS} apt-get install -y sudo openssh-server
chroot ${ROOTFS} apt-get install -y x11-apps mesa-utils
chroot ${ROOTFS} usermod -a -G sudo development

# using chroot on folder and install required packages
chroot ${ROOTFS} apt-get update
chroot ${ROOTFS} apt-get install -y linux-image-amd64 firmware-linux
chroot ${ROOTFS} apt-get install -y xserver-xorg-video-intel xserver-xorg-core xinit
chroot ${ROOTFS} apt-get install -y network-manager 

chroot ${ROOTFS} apt-get install -y openbox kbd
chroot ${ROOTFS} apt-get install -y mesa-utils x11-apps 

# added default user
chroot ${ROOTFS} useradd -m -s /bin/bash -p '$y$j9T$tfjQQVBYroUQisXUtyskm.$IZanMXeYbTRbJ31z2xHbAy.u04FwQeJLXHARAIHKTm1' janez

# copy configurations
cp -ar files ${ROOTFS}
chown -R root:root ${ROOTFS}/files
cp -arp ${ROOTFS}/files/* ${ROOTFS}/
rm -rf ${ROOTFS}/files

# tune configuration
echo "127.0.1.1 deeprey-linux-os" >> ${ROOTFS}/etc/hosts

# enable services
chroot ${ROOTFS} systemctl enable startx.service

# clean downloaded packages
chroot ${ROOTFS} apt-get clean

######################################
########## BUILD IMAGE ###############
######################################
