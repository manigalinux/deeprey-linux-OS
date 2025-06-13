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

# disable root password
sed -i 's|^root:[^:]*:|root::|' ${ROOTFS}/etc/shadow

# add default user
LOG_INFO "Add default user: opencpn"
passhash=$(openssl passwd -6 -salt "$(openssl rand -base64 32)" "$(openssl rand -base64 32)") # random password
chroot ${ROOTFS} useradd -m -s /bin/bash -p "${passhash}" opencpn
chroot ${ROOTFS} usermod -a -G netdev,tty,dialout,input,audio,video,plugdev opencpn

# add admin user
LOG_INFO "Add admin user: deepreyadmin"
passhash=$(openssl passwd -6 -salt "$(openssl rand -base64 32)" "${ADMIN_PASSWORD}") # random password
chroot ${ROOTFS} useradd -m -s /bin/bash -p "${passhash}" deepreyadmin

# add admin related tools and 
chroot ${ROOTFS} apt-get install -y sudo openssh-server # added sudo, openssh
chroot ${ROOTFS} usermod -a -G sudo deepreyadmin

# install host packages
LOG_INFO "Install additional packages (like xserver, kernel, firmware, network manager etc.)"
chroot ${ROOTFS} apt-get update
chroot ${ROOTFS} apt-get install -y linux-image-amd64 firmware-linux firmware-iwlwifi # install linux kernel, firmware and wireless firmware
chroot ${ROOTFS} apt-get install -y xserver-xorg-video-intel xserver-xorg-core xinit # install xserver and intel driver
chroot ${ROOTFS} apt-get install -y network-manager # install network manager
chroot ${ROOTFS} apt-get install -y openbox kbd # install openbox kbd
chroot ${ROOTFS} apt-get install -y mesa-utils x11-apps # install mesa, xclock, xset
chroot ${ROOTFS} apt-get install -y busybox iptables iptables-persistent # install busybox and iptables
chroot ${ROOTFS} apt-get install -y acpid # acpid - catch power buttons pressed

# install official opencpn
LOG_INFO "Install opencpn"
cp -arp Deeprey*.deb ${ROOTFS}/
cp -arp custom_opencpn.deb ${ROOTFS}/
#chroot ${ROOTFS} apt-get install -y libglew2.2 libwxgtk-gl3.2-1 libarchive13 libcurl4 libglu1
chroot ${ROOTFS} dpkg -i custom_opencpn.deb
chroot ${ROOTFS} apt-get -y --fix-broken install

## install original
## chroot ${ROOTFS} apt-get install -y opencpn


##  LOG_INFO "Compile opencpn"
##  apt-get install -y devscripts equivs cmake libgl1-mesa-dev libgl1-mesa-glx libglew-dev  libwxgtk-media3.2-dev libbz2-dev zlib1g-dev  libarchive-dev libpango1.0-dev libcurl4-openssl-dev libusb-1.0-0-dev libssl-dev liblzma-dev libelf-dev libxrandr-dev libgtk-3-dev
##  git clone --depth 1 --branch Release_5.10.2 https://github.com/OpenCPN/OpenCPN.git /OpenCPN
##  #apt-get --allow-unauthenticated install -f
##  mkdir -p /OpenCPN/build
##  #(cd /OpenCPN/build; cmake  -DCMAKE_INSTALL_PREFIX=/opencpn/usr/ ..; make; make install)
##  (cd /OpenCPN/build; cmake ..; make; make DESTDIR=/opencpn/ install)
##  
##  mkdir /opencpn /opencpn/DEBIAN
##  echo -e "Package: opencpn\nVersion: 5.10.2\nDepends: libc6,libglew2.2,libwxgtk-gl3.2-1,libarchive13,libcurl4,libglu1\nMaintainer: Deeprey\nArchitecture: amd64\nDescription: Opencpn application" > /opencpn/DEBIAN/control
##  dpkg-deb --build /opencpn
##  cp /opencpn.deb ${ROOTFS}
##  
##  # install dependencies and opencpn
##  chroot ${ROOTFS} apt-get install -y libglew2.2 libwxgtk-gl3.2-1 libarchive13 libcurl4 libglu1
##  chroot ${ROOTFS} dpkg -i opencpn.deb 

# copy custom configuration from folder "files" (startup scripts, driver parameters)
# files are copied into temporary folder then change owner and groups then copied to rootfs
LOG_INFO "Copy custom configuration files"
cp -ar files ${ROOTFS} 
chown -R root:root ${ROOTFS}/files
chown -R 1000:1000 ${ROOTFS}/files/home/opencpn

cp -arp ${ROOTFS}/tmp/.local ${ROOTFS}/files/home/opencpn/.local
cp -arp ${ROOTFS}/tmp/.opencpn ${ROOTFS}/files/home/opencpn/.opencpn

rm -rf ${ROOTFS}/tmp

chown -R 1000:1000 ${ROOTFS}/files/home/opencpn/.local
chown -R 1000:1000 ${ROOTFS}/files/home/opencpn/.opencpn

chown -R 1001:1001 ${ROOTFS}/files/home/deepreyadmin
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
chroot ${ROOTFS} systemctl enable sshd.service
chroot ${ROOTFS} systemctl enable setup-can0.service
#chroot ${ROOTFS} systemctl enable sshvpn.service

LOG_INFO "Remove unused tty"
for tty in {2..12}; do
    mkdir -p "${ROOTFS}/etc/systemd/system/getty@tty$tty.service.d"
    echo -e "[Service]\nExecStart=\nExecStart=-/bin/false" > "${ROOTFS}/etc/systemd/system/getty@tty$tty.service.d/override.conf"
    chroot ${ROOTFS} systemctl mask getty@tty$tty.service
done

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

# create squashfs
rm ${IMAGES}/rootfs.squashfs
mksquashfs ${ROOTFS} ${IMAGES}/rootfs.squashfs
#mount -t overlay overlay -o lowerdir=/etc,upperdir=/mnt/data/etc,workdir=/mnt/data/.etc-work 

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
#echo -e "DEFAULT boot\nTIMEOUT 0\n\nLABEL boot\n\tLINUX /linux/vmlinuz\n\tINITRD /linux/initrd.img\n\tAPPEND root=UUID=${rootfsuuid} acpi=on loglevel=7 quiet rw pci=noaer noatime nodirtime console=tty1 vconsole.keymap=us no_console_suspend\n" > /mnt/syslinux/syslinux.cfg
echo -e "DEFAULT boot\nTIMEOUT 0\n\nLABEL boot\n\tLINUX /linux/vmlinuz\n\tINITRD /linux/initrd.img\n\tAPPEND root=UUID=${rootfsuuid} boot=overlay acpi=on loglevel=0 quiet rw pci=noaer noatime nodirtime console=tty1 vconsole.keymap=us no_console_suspend\n" > /mnt/syslinux/syslinux.cfg

# create EFI boot (syslinux)
LOG_INFO "Create EFI boot (syslinux)"
cp /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi /mnt/EFI/boot/bootx64.efi
cp /usr/lib/syslinux/modules/efi64/* /mnt/EFI/boot/
cp /mnt/syslinux/syslinux.cfg /mnt/EFI/boot/syslinux.cfg

LOG_INFO "Copy linux kernel and initramfs into EFI partition"
mkdir /mnt/linux
cp ${ROOTFS}/boot/vmlinuz-5.15.0-67-generic /mnt/linux/vmlinuz
cp ${ROOTFS}/boot/initrd.img-5.15.0-67-generic /mnt/linux/initrd.img

LOG_INFO "Unmount EFI partition"
umount /mnt

# mount and copy data
LOG_INFO "Mount and copy data to rootfs partition"
mount ${loopback}p2 /mnt/
#cp -arp ${ROOTFS}/* /mnt/
cp -arp ${IMAGES}/rootfs.squashfs /mnt/
umount /mnt

# destroy loopback
LOG_INFO "Destroy loopback device"
losetup -d ${loopback}
[ -e "${loopback}" ] && rm ${loopback}
[ -e "${loopback}p1" ] && rm ${loopback}p1
[ -e "${loopback}p2" ] && rm ${loopback}p2
