#!/bin/bash

# include config and external functions
source "config"
source "log.sh"

LOG_INFO "Script will remove all data from rootfs and images folder"

######################################
######## SCRIPT CHECKING #############
######################################

# check if rootfs paths is defined
[ "${ROOTFS}" == "" ] && LOG_ERROR "Rootfs folder is '' - must be some folder" && exit 1
[ "${ROOTFS}" == "/" ] && LOG_ERROR "Rootfs folder is '/' - must be some folder" && exit 1
[ "${ROOTFS}" == "//" ] && LOG_ERROR "Rootfs folder is '//' - must be some folder" && exit 1

[ "${IMAGES}" == "" ] && LOG_ERROR "Images folder is '' - must be some folder" && exit 1
[ "${IMAGES}" == "/" ] && LOG_ERROR "Images folder is '/' - must be some folder" && exit 1
[ "${IMAGES}" == "//" ] && LOG_ERROR "Images folder is '//' - must be some folder" && exit 1

# user must be root
[ "$(id -u)" != "0" ] && LOG_ERROR "The user which run this script must be root" && exit 1

# check if folders exist (if not create it)
LOG_INFO "Remove images and rootfs"
[ -d "${ROOTFS}" ] && rm -rf "${ROOTFS}" &>>/dev/null
[ -d "${IMAGES}" ] && rm -rf "${IMAGES}" &>>/dev/null
LOG_INFO "Done"

