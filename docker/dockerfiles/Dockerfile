# syntax=docker/dockerfile:1       
FROM debian:12

ENV DEBIAN_FRONTEND "noninteractive"
ENV TZ "Europe/Ljubljana"
RUN apt-get update            

# install required packages
RUN apt-get -y install debootstrap fdisk dosfstools

# install usefull development packages
RUN apt-get -y install nano
