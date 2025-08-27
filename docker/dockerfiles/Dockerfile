# syntax=docker/dockerfile:1       
FROM debian:12

ENV DEBIAN_FRONTEND "noninteractive"
ENV TZ "Europe/Ljubljana"
RUN apt-get update            

# install required packages
RUN apt-get -y install debootstrap fdisk parted syslinux dosfstools uuid-runtime extlinux syslinux-efi xz-utils squashfs-tools dpkg-dev apt-utils awscli

# install usefull packages
RUN apt-get -y install nano

# Set Environment Variables
ENV ONBOARD_DEB_DIR /onboard/debs
