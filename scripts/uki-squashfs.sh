#!/bin/bash

# -b 1048576 is good number to uki kernel
# mksquashfs /tmp/squashfs-root /root.squashfs -comp xz -b 1048576 -no-append
# right cmdline to  squashfs uki
# "quiet splash ro root=overlay rootfstype=tmpfs"
sudo mkdir -p /usr/lib/dracut/modules.d/99squash-root


##### squash-root Module Setup


echo  "#!/bin/bash

install() {
    # This function includes the squashfs file in the initramfs
    inst /root.squashfs /root.squashfs
    # Include necessary tools for mounting and setting up the overlay
    inst_multiple mkdir mount pivot_root switch_root
    inst_simple /usr/bin/find

    # Include the main script that will run at boot
    inst_hook cmdline 99 "$moddir/squash-root.sh"
} " > /usr/lib/dracut/modules.d/99squash-root/module-setup.sh



### squash-root Script for dracut


echo "#!/bin/bash

# Check for the overlay root kernel command line parameter
if [ "${root}" != "overlay" ]; then
    return
fi

# Create mount points
mkdir -p /run/rootfs /run/overlay /run/upper /run/work

# Mount the embedded squashfs
mount -t squashfs -o ro /root.squashfs /run/rootfs

# Set up the writable tmpfs overlay
mount -t tmpfs -o rw tmpfs /run/overlay
mkdir -p /run/overlay/upper /run/overlay/work

# Create the overlay mount
mount -t overlay overlay -o lowerdir=/run/rootfs,upperdir=/run/overlay/upper,workdir=/run/overlay/work /sysroot

# Switch the root filesystem
mkdir /sysroot/old_root
pivot_root /sysroot /sysroot/old_root

# Execute the real init
exec switch_root /old_root /sbin/init " > /usr/lib/dracut/modules.d/99squash-root/squash-root.sh


### dracut with module

dracut --force --add "99squash-root" /tmp/initramfs-squash.img
