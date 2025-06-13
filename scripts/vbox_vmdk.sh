#!/bin/bash

source "config"

echo "# Disk DescriptorFile
# IDEALLY THE CID SHOULD BE DIFFERENT FOR EVERY DISK. ITS AN OLD RELATIVE OF UUID.
# NOTHING SPECIAL, JUST INVENT ONE. MAKE SURE VBOX DOESN'T SEE TWO DISKS WITH
# THE SAME CID.
version=1
CID=$(openssl rand -hex 4) 
parentCID=ffffffff
createType=\"fullDevice\"

# Extent description
# THE FILESIZE HERE MUST BE THE RAW IMAGE SIZE EXPRESSED IN 512BYTE SECTORS.
# NOTE THE FILENAME TOO, WHICH YOU MUST CORRECT.
RW $(fdisk -l ${IMAGES}/image.img | head -n1 | sed 's/sectors.*//' | awk '{print$NF}') FLAT \"image.img\" 0

# The Disk Data Base
#DDB

ddb.virtualHWVersion = \"4\"
ddb.geometry.cylinders = \"16383\"
ddb.geometry.heads = \"16\"
ddb.geometry.sectors = \"63\"
ddb.adapterType = \"lsilogic\"
ddb.toolsVersion = \"7240\"
ddb.geometry.biosCylinders=\"1024\"
ddb.geometry.biosHeads=\"255\"
ddb.geometry.biosSectors=\"63\"
ddb.uuid.image=\"$(uuidgen)\"
ddb.uuid.modification=\"$(uuidgen)\"
ddb.uuid.parent=\"00000000-0000-0000-0000-000000000000\"
ddb.uuid.parentmodification=\"00000000-0000-0000-0000-000000000000\"
" > ${IMAGES}/image.vmdk

chmod 666 ${IMAGES}/image.vmdk
chmod 666 ${IMAGES}/image.img