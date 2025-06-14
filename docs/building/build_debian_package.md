<!-- omit in toc -->
# Build Instructions for OpenCPN Deeprey Plugins Debian Package

This document provides comprehensive instructions for building the OpenCPN with Deeprey Plugins Debian package on Linux.

<!-- omit in toc -->
## Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
  - [Step 1: Docker Setup](#step-1-docker-setup)
  - [Step 2: Cloning the OpenCPN Source Tree](#step-2-cloning-the-opencpn-source-tree)
  - [Step 3: Cloning Deeprey Plugins Source](#step-3-cloning-deeprey-plugins-source)
  - [Step 4: Enabling Display Linkage](#step-4-enabling-display-linkage)
  - [Step 5: Installing Build Dependencies](#step-5-installing-build-dependencies)
- [Building on Docker](#building-on-docker)

## Introduction
The OpenCPN-Deeprey Debian package provides an installer for OpenCPN with Deeprey plugins installed and enabled by default.

## Prerequisites

### Step 1: Docker Setup

It's recommended to use Docker for building the Debian package to ensure a clean and consistent environment. Avoid using a system with an existing OpenCPN installation to prevent conflicts. Avoid using a system with different Ubuntu versions, as the package is meant to Run on Debian 12 (Bookworm).

```bash
sudo apt-get install docker-compose

cd docker
docker-compose build deeprey-dev-os
docker-compose up -d deeprey-dev-os
```

### Step 2: Cloning the OpenCPN Source Tree
```bash
cd ${YOUR_WORKING_DIRECTORY}
git clone git://github.com/OpenCPN/OpenCPN.git
```

### Step 3: Cloning Deeprey Plugins Source
```bash
cd ${YOUR_WORKING_DIRECTORY}
git clone --recurse-submodules https://github.com/deeprey-marine/deeprey-radar.git
```

```bash
cd ${YOUR_WORKING_DIRECTORY}
git clone --recurse-submodules https://github.com/deeprey-marine/deeprey-gui.git
```

The folder structure should look like this:
```
${YOUR_WORKING_DIRECTORY}
└── deeprey-gui
└── deeprey-linux-os
└── deeprey-radar
└── OpenCPN
```

### Step 4: Enabling Display Linkage
```bash
xhost +local:docker
```

### Step 5: Installing Build Dependencies

**Entering Docker Container**
```bash
docker exec -it deeprey-dev-os /bin/bash
```

**Installing Build Dependencies**
```bash
cd $DEBIAN_PKG_DIR
./set_dev_env.sh
```

## Building on Docker

```bash
cd $DEBIAN_PKG_DIR
./create_dpkg.sh
```

You can also call
```bash
./create_dpkg.sh -y
```
For suppressing all of the user inputs `-y` will always delete all of the old build caches for both OpenCPN legacy, and Deeprey plugins. While `-n` option will always build incrementally on the build cache you already have in `build_release` folder for shorter building time.

This script will create a Debian package for OpenCPN with the Deeprey plugins installed and enabled by default. The resulting `DeepreyPlugins_pi_${GIT_HASH}_amd64.deb` file will be located in the `scripts/debian_pkg` directory.

The build logs will be available for both OpenCPN legacy, and Deeprey plugins in `${YOUR_WORKING_DIRECTORY}/deeprey-linux-os/debian_pkg/logs` directory.
