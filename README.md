# deeprey-linux-os
Deeprey linux OS include environment (docker) and scripts for build Debian OS with minimal GUI (Xorg) environment used for running OpenCPN as kiosk application. Hardware connected with this software are: [maxtang EHL-35](docs/EHL-35.pdf) motherboard with intel CPU and [G121EAN01.2](docs/G121EAN01.2.pdf) 12.1 Inch Color TFT-LCD LVDS display panel.

## Configuration
User configuration is in [scripts/config](scripts/config) file. There are constants as paths where will be stored image and rootfs, and also default admin password. Configurations for different linux proceses and applications are in `scripts/files/etc` folder.

## Environment
Scripts are written and tested on Debian 12 (bookworm) OS. If you use different version of Debian or other GNU/Linux distribution then scripts should be running inside virtual docker container.

### Option 1: docker-compose environment
Your GNU/Linux distribution must have installed `bash` and `docker-compose` application.

Wrappers for using docker environment are in `docker` folder.

To start docker environment use command `docker-compose up`

and enter to docker environment `docker exec -it deeprey-linux-os /bin/bash`

### Option 2: use Debian 12 (bookworm) environment
For running script inisde Debian 12, you need to install additional packages, which are included in next command

```
apt-get install -y debootstrap fdisk parted syslinux dosfstools uuid-runtime extlinux syslinux-efi xz-utils squashfs-tools 
```

### Build
For buildig image change folder to `scripts` and then run `./build.sh`

```
cd scripts
sudo ./build.sh
```

## Copy image to storage
Default location of builded image is in `build/images/image.img` you can copy to storage device as `sudo dd if=build/images/image.img of=/dev/sdX bs=1M oflag=direct status=progress`

## Run and connect to OS
When image is running, the `opencpn` application will automatcally started. Default user `opencpn` doesn't have root permission and has limited access to HW. For root access you can use tty1 (press CTRL+ALT+F1) with admin username `deepreyadmin` and password from `scripts/config` file.

For access you can also use SSH connection with `deepreyadmin` user and password from `scripts/config` file, but default port was changed from 22 to 2345. 

## Hacking
### Known HW/SW related issues

Default graphic kernel driver i915 has a bug in combination of device screen - filickering image (bookworm debian kernel version 6.1). This should be related with [this bug](https://gitlab.freedesktop.org/drm/i915/kernel/-/issues/8146), but fix from page doesn't work. Patch was also sended to i915 [developer team](https://patchwork.freedesktop.org/patch/552713/) but it was reverted.

The main simptom of issue is if picture on display is static then start flickering. If mouse are moved or there are any moving object flickering disappeared.

[![flickering](docs/flickering.png)](docs/flickering.mov)

Workaround is using older kernel - before 6.0. In this case we used ubuntu kernel 5.15.0-67-generic. But solution is not 100% because display start flickering when display goes from sleep state.

### Background of [./build.sh](scripts/build.sh) script

Script `./build.sh` at first check, if host is debian bookworm (12) and if user which runs script is root.

After that create guest rootfs with debootstrap (default path `build/rootfs` - you can change in `scripts/config`) where install all base packages from debian repository. Then create users `opencpn` with random password and `deepreyadmin` with password from `scripts/config` configuration. 

A lot of system configuration will be copied from `script/files` folder. Those files are directly copied, contents are not changed, script change just owner of files to "root:root", except files in `/home` folder (where are user files conected with non root owner). Files in `script/files` are connected with autostart graphic interface, modules, xserver, sshd configuration and so on.

[Workaround for flickering issue](#known-hwsw-related-issues) are in `linux-ubuntu-5.15.0-67-generic.tar.xz` file, where are Ubuntu 20.04.6 kernel (5.15.0-67-generic) and modules. This file is unpacked directly to rootfs folder. After that script rebuild initramfs.

For building image script create empty file and create block device (virtual disk storage) as loopback storage device. On block device create GPT partition, and install syslinux bootloader. Script install lagacy and EFI bootloader.

Linux kernel and initramfs are copied from rootfs into EFI partition in `linux` folder.

In the end script create squashfs and copy it to to 2nd partition.

## Add SSH public key to access to the device without password
As was mentioned before the whole `scripts/files` will be directly copied to rootfs. So if you want to add public certificate key to access to the device via SSH without password, then you can add your `id_rsa.pub` content to `scripts/files/home/deepreyadmin/.ssh/authorized_keys` as:

```
cat id_rsa.pub >> scripts/files/home/deepreyadmin/.ssh/authorized_keys
```

After build `authorized_keys` file will be on your image and you can access to device via SSH With certificate over 2345.

## Changing SSH connection port
For changing SSH connection port please change Port number 2345 to your number in file [scripts/files/etc/ssh/sshd_config](scripts/files/etc/ssh/sshd_config) (line 14).

You need also open port in `iptables` firewall [scripts/files/etc/iptables/rules.v4](scripts/files/etc/iptables/rules.v4) where you change line no.: 6 from `-A OUTPUT -p tcp -m tcp --sport 2345 -j ACCEPT` to `-A OUTPUT -p tcp -m tcp --sport YOUR_PORT -j ACCEPT`.
