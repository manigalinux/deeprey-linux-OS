# Script to clean up OpenCPN installation files
# This script will remove all OpenCPN related files from the system
#!/bin/bash
echo "Cleaning up OpenCPN installed binaries and configurations..."

# Adding a check to ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please run it with sudo or as the root user."
    exit 1
fi

# Requesting confirmation before proceeding or -y option
if [[ "$1" != "-y" ]]; then
    if [[ "$1" != "-n" ]]; then
        read -p "Are you sure you want to remove all OpenCPN related files? This action cannot be undone. (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            exit 0
        fi
    fi
fi

echo "Removing OpenCPN related files without confirmation..."

# Remove OpenCPN related files from system directories
rm -rf /usr/local/bin/opencpn*
rm -rf /usr/local/lib/opencpn
rm -rf /usr/local/share/opencpn
rm -rf /usr/local/share/locale
rm -rf /usr/local/share/doc/opencpn
rm -rf /usr/local/share/applications/opencpn*
rm -rf /usr/local/share/man/man1/opencpn*
rm -rf /usr/local/share/icons/hicolor/48x48/apps/opencpn*
rm -rf /usr/local/share/icons/hicolor/64x64/apps/opencpn*
rm -rf /usr/local/share/icons/hicolor/scalable/apps/opencpn*
rm -rf /usr/local/share/metainfo/opencpn*
rm -rf $HOME/.opencpn
rm -rf $HOME/.local/lib/opencpn
rm -rf $HOME/.local/share/opencpn
rm -rf $HOME/.local/share/locale