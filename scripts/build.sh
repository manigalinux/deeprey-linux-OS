#!/bin/bash
source "config"

# constants
DEBIAN_VERSION="bookworm" # bookworm:12
DEBIAN_ARCH="amd64"
IMAGE_SIZE=3000 # size ofimage in MB

# TODO: check GNU/Linux distribution

# TODO: check ROOTFS - must be something except / or empty

# user must be root
[ "$(id -u)" != "0" ] && exit 1

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
chown -R 1001:1001 ${ROOTFS}/files/home/janez
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

# create empty bock file
dd if=/dev/zero of=${IMAGES}/image.img bs=1M count=${IMAGE_SIZE}
chmod 666 ${IMAGES}/image.img

# create loopback device
loopback=$(losetup -f)

if ! losetup ${loopback} ${IMAGES}/image.img
then
    # docker workaround
    lonum=$(echo "${loopback}" | sed 's|/dev/loop||g')
    mknod -m 660 /dev/loop${lonum} b 7 ${lonum}
    losetup ${loopback} ${IMAGES}/image.img
fi

# create GPT partition layout
echo -e "g

n
1

+64M
t
1

n
2



x
A
1
r

w" | fdisk ${IMAGES}/image.img

# show all partitions as /dev/loopXp
partprobe ${loopback}
partitions=$(lsblk --raw --output "MAJ:MIN" --noheadings ${loopback} | tail -n +2)
counter=1
for i in ${partitions}; do
    maj=$(echo $i | cut -d: -f1)
    min=$(echo $i | cut -d: -f2)
    if [ ! -e "${loopback}p${counter}" ]; then echo "mknod ${loopback}p${counter} b ${maj} ${min}" && mknod ${loopback}p${counter} b ${maj} ${min}; fi
    counter=$((counter + 1))
done

# create filesystems
mkfs.fat -F32 -s1 ${loopback}p1
mkfs.ext4 ${loopback}p2

rootfsuuid=$(blkid -s UUID -o value "${loopback}p2")

mount ${loopback}p1 /mnt

# create legacy boot (syslinux)
dd bs=440 count=1 conv=notrunc if=/usr/lib/syslinux/mbr/gptmbr.bin of=${loopback}
mkdir -p /mnt/syslinux /mnt/EFI/boot/
cp /usr/lib/syslinux/modules/bios/* /mnt/syslinux/
extlinux --install /mnt/syslinux
# set boot configuration
echo -e "DEFAULT boot\nTIMEOUT 0\n\nLABEL boot\n\tLINUX /linux/vmlinuz\n\tINITRD /linux/initrd.img\n\tAPPEND root=UUID=${rootfsuuid} rw\n" > /mnt/syslinux/syslinux.cfg

# create EFI boot (syslinux)
cp /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi /mnt/EFI/boot/bootx64.efi
cp /usr/lib/syslinux/modules/efi64/* /mnt/EFI/boot/
echo -e "DEFAULT boot\nTIMEOUT 0\n\nLABEL boot\n\tLINUX /linux/vmlinuz\n\tINITRD /linux/initrd.img\n\tAPPEND root=UUID=${rootfsuuid} rw\n" > /mnt/EFI/boot/syslinux.cfg

# copy kernel and initramfs to boot partition - TODO: find better solution
mkdir /mnt/linux
cp ${ROOTFS}/vmlinuz /mnt/linux
cp ${ROOTFS}/initrd.img /mnt/linux

umount /mnt

# mount and copy data
mount ${loopback}p2 /mnt/
cp -arp ${ROOTFS}/* /mnt/
umount /mnt

# destroy loopback
losetup -d ${loopback}
[ -e "${loopback}" ] && rm ${loopback}
[ -e "${loopback}p1" ] && rm ${loopback}p1
[ -e "${loopback}p2" ] && rm ${loopback}p2
