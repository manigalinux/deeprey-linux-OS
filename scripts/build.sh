#!/bin/bash

# include config and external functions
source "config"
source "log.sh"

# constants
DEBIAN_VERSION="bookworm" # bookworm:12
DEBIAN_ARCH="amd64" # archicecture of image
IMAGE_SIZE=10000 # size of image in MB


######################################
######## SCRIPT CHECKING #############
######################################

# check host GNU/Linux distribution (must be debian 12 - bookworm)
[ ! -f /etc/debian_version ] && LOG_ERROR "Host distribution must be Debian bookworm" && exit 1
if ! grep -q "^12\." /etc/debian_version
then
    LOG_ERROR "Host distribution must be Debian 12 (bookworm)"
    exit 1
fi

# check if rootfs/images paths is defined
[ "${ROOTFS}" == "" ] && LOG_ERROR "Rootfs folder is '' - must be some folder" && exit 1
[ "${ROOTFS}" == "/" ] && LOG_ERROR "Rootfs folder is '/' - must be some folder" && exit 1
[ "${ROOTFS}" == "//" ] && LOG_ERROR "Rootfs folder is '//' - must be some folder" && exit 1
[ "${IMAGES}" == "" ] && LOG_ERROR "Images folder is '' - must be some folder" && exit 1
[ "${IMAGES}" == "/" ] && LOG_ERROR "Images folder is '/' - must be some folder" && exit 1
[ "${IMAGES}" == "//" ] && LOG_ERROR "Images folder is '//' - must be some folder" && exit 1


# user must be root
[ "$(id -u)" != "0" ] && LOG_ERROR "The user which run this script must be root" && exit 1

# check if folders exist (if not create it)
[ ! -d ${ROOTFS} ] && mkdir "${ROOTFS}" &>>/dev/null
[ ! -d ${IMAGES} ] && mkdir "${IMAGES}" &>>/dev/null


######################################
########## BUILD ROOTFS ##############
######################################

# debootstrap to rootfs folder
LOG_INFO "Debootstrap base debian distibution (${DEBIAN_VERSION})"
debootstrap --arch ${DEBIAN_ARCH} ${DEBIAN_VERSION} ${ROOTFS} https://deb.debian.org/debian

# update repository source lists
LOG_INFO "Updating guest repositories"
sed -i 's/main$/main contrib non-free-firmware/g' ${ROOTFS}/etc/apt/sources.list # bookworm (firmware for i915 and iwlwifi drivers)
echo 'deb http://deb.debian.org/debian bookworm-backports main' >> ${ROOTFS}/etc/apt/sources.list # repository for official opencpn application

# added default user
LOG_INFO "Added default user"
chroot ${ROOTFS} useradd -m -s /bin/bash -p '$y$j9T$omjeV.F9RBuRT6uiB8N8L0$zPqVN0qa3Hz/fAvqK0k8.oA4BqDmg2zOXjfvO2TFPN5' janez

# add development stuff - just for development (pass: x)
LOG_INFO "Added development stuff (user, ssh, sudo etc.)"
chroot ${ROOTFS} useradd -m -s /bin/bash -p '$y$j9T$omjeV.F9RBuRT6uiB8N8L0$zPqVN0qa3Hz/fAvqK0k8.oA4BqDmg2zOXjfvO2TFPN5' development # add user with password x
chroot ${ROOTFS} apt-get install -y sudo openssh-server # added sudo, openssh
chroot ${ROOTFS} apt-get install -y x11-apps mesa-utils # add xclock, 
chroot ${ROOTFS} usermod -a -G sudo development # add development user to sudo group
chroot ${ROOTFS} usermod -a -G sudo janez # add default user to sudo group

# install host packages
LOG_INFO "Install additional packages (like xserver, kernel, firmware, network manager etc.)"
chroot ${ROOTFS} apt-get update
chroot ${ROOTFS} apt-get install -y linux-image-amd64 firmware-linux firmware-iwlwifi # install linux kernel, firmware and wireless firmware
chroot ${ROOTFS} apt-get install -y xserver-xorg-video-intel xserver-xorg-core xinit # install xserver and intel driver
chroot ${ROOTFS} apt-get install -y network-manager # install network manager
chroot ${ROOTFS} apt-get install -y openbox kbd # install openbox kbd
chroot ${ROOTFS} apt-get install -y mesa-utils x11-apps # install mesa, xclock, xset

# install official opencpn
LOG_INFO "Install opencpn"
chroot ${ROOTFS} apt-get install -y opencpn

# copy custom configuration from folder "files" (startup scripts, driver parameters)
# files are copied into temporary folder then change owner and groups then copied to rootfs
LOG_INFO "Copy custom configuration files"
cp -ar files ${ROOTFS} 
chown -R root:root ${ROOTFS}/files
chown -R 1000:1000 ${ROOTFS}/files/home/janez
chown -R 1001:1001 ${ROOTFS}/files/home/development
cp -arp ${ROOTFS}/files/* ${ROOTFS}/
rm -rf ${ROOTFS}/files

# unpack custom kernel/modules and so on (also change owner to root)
LOG_INFO "Unpack custom kernel - ubuntu kernel 5.15.0-67-generic"
tar xf linux-ubuntu-5.15.0-67-generic.tar.xz -C ${ROOTFS}/

# update initramfs
LOG_INFO "Update initramfs"
chroot ${ROOTFS} update-initramfs -c -k 5.15.0-67-generic

# tune configuration
LOG_INFO "Update /etc/hosts file"
echo "127.0.1.1 deeprey-linux-os" >> ${ROOTFS}/etc/hosts

# enable services
LOG_INFO "Enable systemd services"
chroot ${ROOTFS} systemctl enable startx.service
# chroot ${ROOTFS} systemctl enable sshvpn.service

# clean downloaded packages
LOG_INFO "Clean downloaded apt packages"
chroot ${ROOTFS} apt-get clean

######################################
########## BUILD IMAGE ###############
######################################

# create empty bock file
LOG_INFO "Create empty block file"
dd if=/dev/zero of=${IMAGES}/image.img bs=1M count=${IMAGE_SIZE} &>> /dev/null
chmod 666 ${IMAGES}/image.img # change permission

# create loopback device
LOG_INFO "Create loopback device"
loopback=$(losetup -f)

LOG_INFO "Added block file to loopback device"
if ! losetup ${loopback} ${IMAGES}/image.img
then
    # docker workaround
    lonum=$(echo "${loopback}" | sed 's|/dev/loop||g')
    mknod -m 660 /dev/loop${lonum} b 7 ${lonum}
    losetup ${loopback} ${IMAGES}/image.img
fi

# create GPT partition layout
LOG_INFO "Create GPT partition layout"
echo -e "g

n
1

+512M
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
LOG_INFO "Partprobe partitions"
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
LOG_INFO "Create partitions"
mkfs.fat -F32 -s1 ${loopback}p1
mkfs.ext4 ${loopback}p2

rootfsuuid=$(blkid -s UUID -o value "${loopback}p2") # get rootfs partition UUID

LOG_INFO "Mount EFI partition"
mount ${loopback}p1 /mnt

# create legacy boot (syslinux)
LOG_INFO "Create legacy boot (syslinux)"
dd bs=440 count=1 conv=notrunc if=/usr/lib/syslinux/mbr/gptmbr.bin of=${loopback}
mkdir -p /mnt/syslinux /mnt/EFI/boot/
cp /usr/lib/syslinux/modules/bios/* /mnt/syslinux/
extlinux --install /mnt/syslinux
# set boot configuration
#echo -e "DEFAULT boot\nTIMEOUT 0\n\nLABEL boot\n\tLINUX /linux/vmlinuz\n\tINITRD /linux/initrd.img\n\tAPPEND root=UUID=${rootfsuuid} acpi=off loglevel=0 quiet rw pci=nomsi\n" > /mnt/syslinux/syslinux.cfg
#echo -e "DEFAULT boot\nTIMEOUT 0\n\nLABEL boot\n\tLINUX /linux/vmlinuz\n\tINITRD /linux/initrd.img\n\tAPPEND root=UUID=${rootfsuuid} acpi=off loglevel=7 quiet rw pci=noaer\n" > /mnt/syslinux/syslinux.cfg #v13
#echo -e "DEFAULT boot\nTIMEOUT 0\n\nLABEL boot\n\tLINUX /linux/vmlinuz\n\tINITRD /linux/initrd.img\n\tAPPEND root=UUID=${rootfsuuid} loglevel=7 quiet rw pci=noaer\n" > /mnt/syslinux/syslinux.cfg #v12
echo -e "DEFAULT boot\nTIMEOUT 0\n\nLABEL boot\n\tLINUX /linux/vmlinuz\n\tINITRD /linux/initrd.img\n\tAPPEND root=UUID=${rootfsuuid} acpi=on loglevel=7 quiet rw pci=noaer noatime nodirtime console=ttyS0\n" > /mnt/syslinux/syslinux.cfg #v14

# create EFI boot (syslinux)
LOG_INFO "Create EFI boot (syslinux)"
cp /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi /mnt/EFI/boot/bootx64.efi
cp /usr/lib/syslinux/modules/efi64/* /mnt/EFI/boot/
cp /mnt/syslinux/syslinux.cfg /mnt/EFI/boot/syslinux.cfg
#echo -e "DEFAULT boot\nTIMEOUT 0\n\nLABEL boot\n\tLINUX /linux/vmlinuz\n\tINITRD /linux/initrd.img\n\tAPPEND root=UUID=${rootfsuuid} acpi=off loglevel=7 quiet rw pci=noaer\n" > /mnt/EFI/boot/syslinux.cfg # v13
#echo -e "DEFAULT boot\nTIMEOUT 0\n\nLABEL boot\n\tLINUX /linux/vmlinuz\n\tINITRD /linux/initrd.img\n\tAPPEND root=UUID=${rootfsuuid} loglevel=7 quiet rw pci=noaer\n" > /mnt/EFI/boot/syslinux.cfg #v12
#echo -e "DEFAULT boot\nTIMEOUT 0\n\nLABEL boot\n\tLINUX /linux/vmlinuz\n\tINITRD /linux/initrd.img\n\tAPPEND root=UUID=${rootfsuuid} acpi=on loglevel=7 quiet rw pci=noaer noatime nodirtime console=ttyS0\n" > /mnt/EFI/boot/syslinux.cfg # v14

LOG_INFO "Copy linux kernel and initramfs into EFI partition"
mkdir /mnt/linux
cp ${ROOTFS}/boot/vmlinuz-5.15.0-67-generic /mnt/linux/vmlinuz
cp ${ROOTFS}/boot/initrd.img-5.15.0-67-generic /mnt/linux/initrd.img

LOG_INFO "Unmount EFI partition"
umount /mnt

# mount and copy data
LOG_INFO "Mount and copy data to rootfs partition"
mount ${loopback}p2 /mnt/
cp -arp ${ROOTFS}/* /mnt/
umount /mnt

# destroy loopback
LOG_INFO "Destroy loopback device"
losetup -d ${loopback}
[ -e "${loopback}" ] && rm ${loopback}
[ -e "${loopback}p1" ] && rm ${loopback}p1
[ -e "${loopback}p2" ] && rm ${loopback}p2
