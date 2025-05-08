# syntax=docker/dockerfile:1       
FROM debian:12

ENV DEBIAN_FRONTEND "noninteractive"
ENV TZ "Europe/Ljubljana"
RUN apt-get update            

# install required packages
RUN apt-get -y install debootstrap fdisk parted syslinux dosfstools uuid-runtime extlinux syslinux-efi 

# install usefull packages
RUN apt-get -y install nano
