#!/bin/bash

#sudo apt install python3 python3-pefile python3-zstandard python3-cryptography python3-lz4
#git clone https://github.com/systemd/systemd.git
#cd systemd/src/ukify

#cp ukify.py /usr/bin

#echo "#!/bin/bash
#python3 /usr/bin/ukify.py $*" > /bin/ukify
#chmod 755 /bin/ukify



#apt install systemd-boot sbsigntool


mkdir /tmp/uki-build
cd /tmp/uki-build

KERNEL_VERSION=$(uname -r)
cp /boot/vmlinuz-${KERNEL_VERSION} .
#cp /boot/initrd.img-${KERNEL_VERSION} .

dracut  --force  /tmp/uki-build/initrd.img-${KERNEL_VERSION}


PARTITION="/dev/sda3" 

# Get the UUID of the specified partition
UUID=$(blkid -s UUID -o value "$PARTITION")

echo "root=UUID=${UUID} ro quiet" > cmdline

/usr/bin/python3 /bin/ukify.py build --uname=${KERNEL_VERSION} \
	    --linux=vmlinuz-${KERNEL_VERSION} \
            --initrd=initrd.img-${KERNEL_VERSION} \
            --cmdline="root=UUID=${UUID} quiet ro" \
            --os-release=/etc/os-release \
            --output=uki-deeprey-os-${KERNEL_VERSION}.efi


#objcopy \
#  --add-section .osrel="/etc/os-release" --change-section-vma .osrel=0x20000 \
#  --add-section .cmdline="cmdline" --change-section-vma .cmdline=0x30000 \
#  --add-section .linux="vmlinuz-${KERNEL_VERSION}" --change-section-vma .linux=0x40000 \
#  --add-section .initrd="initrd.img-${KERNEL_VERSION}" --change-section-vma .initrd=0x50000 \
#  /usr/lib/systemd/boot/efi/linuxx64.efi.stub uki-deeprey-os-${KERNEL_VERSION}.efi
#
#

#objcopy \
#  --add-section .osrel="/etc/os-release" --set-section-flags .osrel=readonly \
#  --add-section .cmdline="cmdline" --set-section-flags .cmdline=readonly \
#  --add-section .linux="vmlinuz-$(uname -r)" --set-section-flags .linux=readonly \
#  --add-section .initrd="initrd.img-$(uname -r)" --set-section-flags .initrd=readonly \
#  /usr/lib/systemd/boot/efi/linuxx64.efi.stub uki-deeprey-os-${KERNEL_VERSION}.efi




cp uki-deeprey-os-${KERNEL_VERSION}.efi /boot/efi/EFI/deepreyos/

# /boot/efi/loader/entries/uki-debian.conf

echo "title deeprey-linux-os GNU/Linux 
linux /EFI/deepreyos/uki-deeprey-os-${KERNEL_VERSION}.efi" > /boot/efi/loader/entries/uki-deeprey-os.conf
