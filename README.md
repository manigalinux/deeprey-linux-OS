# deeprey-linux-os
Deepry linux OS include environment (docker) and scripts for build Debian OS, with minimal GUI (Xorg) environment using for running OpenCPN as kiosk application.

## Environment
Scripts are written and tested on Debian 12 (bookworm) OS. If you use different version of Debian or other GNU/Linux distribution then scripts should be running inside virtual docker container.

### Build inside Debian 12 (bookworm)
For running script inisde Debian 12, you need to install additional packages, which are included in next command

```
apt-get install -y sed debootstrap
```
### Build inside docker-compose environment
Your GNU/Linux distribution must have installed `bash` and `docker-compose` application.

Wrappers for using docker environment are in `docker` folder.

To start docker environment use command `docker-compose up`

## Configuration
User configuration is in `scripts/config` file. There you can reconfigure folder paths (where will be images, rootfs and so on)

## Build
For buildig image change folder to `scripts` and then run `./build.sh`

```
cd scripts
./build.sh
```

If you use docker envirnoment then you run:
```
cd scripts
./build.sh
```
And be sure that docker container is running `docker-compose up`

## Copy image to storage
Default location of builded image is in `build/images/image.img` you can copy to storage device as `sudo dd if=build/images/image.img of=/dev/sdX bs=1M oflag=direct status=progress`

