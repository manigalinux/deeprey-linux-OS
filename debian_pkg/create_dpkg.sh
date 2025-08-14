# This script builds the DeepreyGui plugin for OpenCPN and prepares it for packaging.
# It assumes that the OpenCPN build environment is already set up.
# It also assumes that the necessary dependencies are installed.
# Usage: ./build_deeprey_gui.sh

# The script must be run inside docker container to avoid issues with missing dependencies.
# Ensure you have the necessary permissions to run this script
# and that you have Docker installed and running.

# Checks if the user is root from docker container $USER == root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please run it with sudo or as the root user."
    exit 1
fi

# Defining scripts variables
# Checks if the repository directory is defined as environment variable
if [ ! -d "$OPENCPN_DIR" ]; then
    echo "OpenCPN source directory not found at $OPENCPN_DIR."
    exit 1
fi

if [ ! -d "$DEEPREY_GUI_DIR" ]; then
    echo "DeepreyGUI source directory not found at $DEEPREY_GUI_DIR."
    exit 1
fi

if [ ! -d "$DEEPREY_RADAR_DIR" ]; then
    echo "DeepreyRadar source directory not found at $DEEPREY_RADAR_DIR."
    exit 1
fi

if [ ! -d "$DEEPREY_SONAR_DIR" ]; then
    echo "DeepreySonar source directory not found at $DEEPREY_SONAR_DIR."
    exit 1
fi

if [ ! -d "$DEEPREY_NAVBAR_DIR" ]; then
    echo "DeepreyNavbar source directory not found at $DEEPREY_NAVBAR_DIR."
    exit 1
fi

if [ ! -d "$DEBIAN_PKG_DIR" ]; then
    echo "debian_pkg directory not found at $DEBIAN_PKG_DIR."
    exit 1
fi

echo "DEBIAN Directory: $DEBIAN_PKG_DIR"
echo "DeepreyGui Directory: $DEEPREY_GUI_DIR"
echo "DeepreyRadar Directory: $DEEPREY_RADAR_DIR"
echo "DeepreySonar Directory: $DEEPREY_SONAR_DIR"
echo "DeepreyNavbar Directory: $DEEPREY_NAVBAR_DIR"
echo "OpenCPN Directory: $OPENCPN_DIR"

DEEPREY_GUI_BUILD_DIR="$DEEPREY_GUI_DIR/build_release"
DEEPREY_RADAR_BUILD_DIR="$DEEPREY_RADAR_DIR/build_release"
DEEPREY_SONAR_BUILD_DIR="$DEEPREY_SONAR_DIR/build_release"
DEEPREY_NAVBAR_BUILD_DIR="$DEEPREY_NAVBAR_DIR/build_release"
OPENCPN_BUILD_DIR="$OPENCPN_DIR/build_release"
DEBIAN_PKG_SRC_FOLDER=$DEBIAN_PKG_DIR/deeprey_pkg

LOG_DIR="$DEBIAN_PKG_DIR/logs"
# Ensure the log directory exists
# removing old log directory if it exists
if [ -d "$LOG_DIR" ]; then
    echo "Removing old log directory..."
    rm -rf "$LOG_DIR"
fi
# Create a new log directory
echo "Creating log directory at $LOG_DIR..."
mkdir -p "$LOG_DIR"

echo "# ============================================================ #"

#!/bin/bash
# Removing old opencpn if it exists
./clean_opencpn.sh $1
echo "# ============================================================ #"

# Building OpenCPN from Source to get the latest binaries
echo "Building OpenCPN from Source..."
cd $OPENCPN_DIR
if [ ! -d $OPENCPN_BUILD_DIR ]; then
    mkdir -p $OPENCPN_BUILD_DIR
else
    # Checks whether the user want a fresh build or not, or if -y option is passed
    if [[ "$1" == "-y" ]]; then
        echo "Removing old OpenCPN build directory..."
        rm -rf $OPENCPN_BUILD_DIR
    else
        if [[ "$1" != "-n" ]]; then
            read -p "Do you want to remove the old OpenCPN build directory? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo "Removing old OpenCPN build directory..."
                rm -rf $OPENCPN_BUILD_DIR
            fi
        fi
    fi
fi
# Ensure we are in the OpenCPN directory and save log output to the file
cmake -B $OPENCPN_BUILD_DIR -DCMAKE_BUILD_TYPE=Release > "$LOG_DIR/opencpn_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ CMake configuration failed"
    exit 1
fi
echo "Configuring OpenCPN build..."
cmake --build $OPENCPN_BUILD_DIR --config Release -- -j8 >> "$LOG_DIR/opencpn_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ OpenCPN build failed"
    exit 1
fi
echo "✅ OpenCPN build successful"
# Install OpenCPN
echo "Installing OpenCPN..."
cd $OPENCPN_BUILD_DIR
make install >> "$LOG_DIR/opencpn_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ OpenCPN installation failed"
    exit 1
fi

echo "# ============================================================ #"

# Building DeepreyGui plugin
echo "Building DeepreyGui plugin..."
cd $DEEPREY_GUI_DIR

if [ ! -d $DEEPREY_GUI_BUILD_DIR ]; then
    mkdir -p $DEEPREY_GUI_BUILD_DIR
else
    # Checks whether the user want a fresh build or not, or if -y option is passed
    if [[ "$1" == "-y" ]]; then
        echo "Removing old DeepreyGui build directory..."
        rm -rf $DEEPREY_GUI_BUILD_DIR
    else
        if [[ "$1" != "-n" ]]; then
            read -p "Do you want to remove the old DeepreyGui build directory? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo "Removing old DeepreyGui build directory..."
                rm -rf $DEEPREY_GUI_BUILD_DIR
            fi
        fi
    fi
fi

cmake -B $DEEPREY_GUI_BUILD_DIR -DCMAKE_BUILD_TYPE=Release > "$LOG_DIR/deeprey_gui_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ CMake configuration failed"
    exit 1
fi
echo "Configuring DeepreyGui build..."
cmake --build $DEEPREY_GUI_BUILD_DIR --config Release -- -j8 >> "$LOG_DIR/deeprey_gui_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ DeepreyGui build failed"
    exit 1
fi
echo "✅ DeepreyGui build successful"
# Install OpenCPN
echo "Installing DeepreyGui..."
cd $DEEPREY_GUI_BUILD_DIR
make >> "$LOG_DIR/deeprey_gui_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ DeepreyGui installation failed"
    exit 1
fi

echo "# ============================================================ #"

# Building DeepreyRadar plugin
echo "Building DeepreyRadar plugin..."
cd $DEEPREY_RADAR_DIR

if [ ! -d $DEEPREY_RADAR_BUILD_DIR ]; then
    mkdir -p $DEEPREY_RADAR_BUILD_DIR
else
    # Checks whether the user want a fresh build or not, or if -y option is passed
    if [[ "$1" == "-y" ]]; then
        echo "Removing old DeepreyRADAR build directory..."
        rm -rf $DEEPREY_RADAR_BUILD_DIR
    else
        if [[ "$1" != "-n" ]]; then
            read -p "Do you want to remove the old DeepreyRadar build directory? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo "Removing old DeepreyRadar build directory..."
                rm -rf $DEEPREY_RADAR_BUILD_DIR
            fi
        fi
    fi
fi

cmake -B $DEEPREY_RADAR_BUILD_DIR -DCMAKE_BUILD_TYPE=Release > "$LOG_DIR/deeprey_radar_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ CMake configuration failed"
    exit 1
fi
echo "Configuring DeepreyRadar build..."
cmake --build $DEEPREY_RADAR_BUILD_DIR --config Release -- -j8 >> "$LOG_DIR/deeprey_radar_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ DeepreyRadar build failed"
    exit 1
fi
echo "✅ DeepreyRadar build successful"
# Install OpenCPN
echo "Installing DeepreyRadar..."
cd $DEEPREY_RADAR_BUILD_DIR
make >> "$LOG_DIR/deeprey_radar_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ DeepreyRadar installation failed"
    exit 1
fi

echo "# ============================================================ #"

# # Building DeepreySonar plugin
# echo "Building DeepreySonar plugin..."
# cd $DEEPREY_SONAR_DIR

# if [ ! -d $DEEPREY_SONAR_BUILD_DIR ]; then
#     mkdir -p $DEEPREY_SONAR_BUILD_DIR
# else
#     # Checks whether the user want a fresh build or not, or if -y option is passed
#     if [[ "$1" == "-y" ]]; then
#         echo "Removing old DeepreySONAR build directory..."
#         rm -rf $DEEPREY_SONAR_BUILD_DIR
#     else
#         if [[ "$1" != "-n" ]]; then
#             read -p "Do you want to remove the old DeepreySonar build directory? (y/N): " confirm
#             if [[ "$confirm" =~ ^[Yy]$ ]]; then
#                 echo "Removing old DeepreySonar build directory..."
#                 rm -rf $DEEPREY_SONAR_BUILD_DIR
#             fi
#         fi
#     fi
# fi

# cmake -B $DEEPREY_SONAR_BUILD_DIR -DCMAKE_BUILD_TYPE=Release > "$LOG_DIR/deeprey_sonar_build.log" 2>&1
# if [ $? -ne 0 ]; then
#     echo "❌ CMake configuration failed"
#     exit 1
# fi
# echo "Configuring DeepreySonar build..."
# cmake --build $DEEPREY_SONAR_BUILD_DIR --config Release -- -j8 >> "$LOG_DIR/deeprey_sonar_build.log" 2>&1
# if [ $? -ne 0 ]; then
#     echo "❌ DeepreySonar build failed"
#     exit 1
# fi
# echo "✅ DeepreySonar build successful"
# Install OpenCPN
echo "Installing DeepreySonar..."
cd $DEEPREY_SONAR_BUILD_DIR
make >> "$LOG_DIR/deeprey_sonar_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ DeepreySonar installation failed"
    exit 1
fi

echo "# ============================================================ #"

# Building DeepreyNavbar plugin
echo "Building DeepreyNavbar plugin..."
cd $DEEPREY_NAVBAR_DIR

if [ ! -d $DEEPREY_NAVBAR_BUILD_DIR ]; then
    mkdir -p $DEEPREY_NAVBAR_BUILD_DIR
else
    # Checks whether the user want a fresh build or not, or if -y option is passed
    if [[ "$1" == "-y" ]]; then
        echo "Removing old DeepreyNavbar build directory..."
        rm -rf $DEEPREY_NAVBAR_BUILD_DIR
    else
        if [[ "$1" != "-n" ]]; then
            read -p "Do you want to remove the old DeepreyNavbar build directory? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo "Removing old DeepreyNavbar build directory..."
                rm -rf $DEEPREY_NAVBAR_BUILD_DIR
            fi
        fi
    fi
fi

cmake -B $DEEPREY_NAVBAR_BUILD_DIR -DCMAKE_BUILD_TYPE=Release > "$LOG_DIR/deeprey_navbar_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ CMake configuration failed"
    exit 1
fi
echo "Configuring DeepreyNavbar build..."
cmake --build $DEEPREY_NAVBAR_BUILD_DIR --config Release -- -j8 >> "$LOG_DIR/deeprey_navbar_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ DeepreyNavbar build failed"
    exit 1
fi
echo "✅ DeepreyNavbar build successful"
# Install OpenCPN
echo "Installing DeepreyNavbar..."
cd $DEEPREY_NAVBAR_BUILD_DIR
make >> "$LOG_DIR/deeprey_navbar_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ DeepreyNavbar installation failed"
    exit 1
fi

echo "# ============================================================ #"

# Removing old package directory if it exists
rm -rf $DEBIAN_PKG_SRC_FOLDER/usr

# Create the package directory structure
echo "Creating package directory structure..."

# Copying OpenCPN binaries
mkdir -p $DEBIAN_PKG_SRC_FOLDER/usr/local/bin
cp -r /usr/local/bin/opencpn* $DEBIAN_PKG_SRC_FOLDER/usr/local/bin

# Creating Locale folders
mkdir -p $DEBIAN_PKG_SRC_FOLDER/usr/local/share/locale

# Copying OpenCPN locale files
find /usr/local/share/locale -type f -path "*/LC_MESSAGES/opencpn.mo" -exec cp --parents {} $DEBIAN_PKG_SRC_FOLDER \;

mkdir -p $DEBIAN_PKG_SRC_FOLDER/usr/local/share/man/man1
cp /usr/local/share/man/man1/opencpn* $DEBIAN_PKG_SRC_FOLDER/usr/local/share/man/man1

# Copying OpenCPN App files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/usr/local/share/applications
cp /usr/local/share/applications/opencpn* $DEBIAN_PKG_SRC_FOLDER/usr/local/share/applications

# Copying OpenCPN doc files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/usr/local/share/doc
cp -r /usr/local/share/doc/opencpn $DEBIAN_PKG_SRC_FOLDER/usr/local/share/doc

# Copying OpenCPN icons
mkdir -p $DEBIAN_PKG_SRC_FOLDER/usr/local/share/icons/hicolor/48x48/apps
cp /usr/local/share/icons/hicolor/48x48/apps/opencpn* $DEBIAN_PKG_SRC_FOLDER/usr/local/share/icons/hicolor/48x48/apps

mkdir -p $DEBIAN_PKG_SRC_FOLDER/usr/local/share/icons/hicolor/64x64/apps
cp /usr/local/share/icons/hicolor/64x64/apps/opencpn* $DEBIAN_PKG_SRC_FOLDER/usr/local/share/icons/hicolor/64x64/apps

mkdir -p $DEBIAN_PKG_SRC_FOLDER/usr/local/share/icons/hicolor/scalable/apps
cp /usr/local/share/icons/hicolor/scalable/apps/opencpn* $DEBIAN_PKG_SRC_FOLDER/usr/local/share/icons/hicolor/scalable/apps

# Copying OpenCPN metainfo files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/usr/local/share/metainfo
cp /usr/local/share/metainfo/opencpn* $DEBIAN_PKG_SRC_FOLDER/usr/local/share/metainfo

# Copying OpenCPN files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/usr/local/share/opencpn
cp -r /usr/local/share/opencpn $DEBIAN_PKG_SRC_FOLDER/usr/local/share

# Removing OpenCPN old plugins
rm -rf $DEBIAN_PKG_SRC_FOLDER/usr/local/share/opencpn/plugins
mkdir -p $DEBIAN_PKG_SRC_FOLDER/usr/local/share/opencpn/plugins

# Creating temp directory for $USER folder copying
rm -rf $DEBIAN_PKG_SRC_FOLDER/tmp/.local

# Adding DeepreyGui plugin files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/tmp/.local/lib/opencpn
cp $DEEPREY_GUI_BUILD_DIR/libDeepreyGui_pi.so $DEBIAN_PKG_SRC_FOLDER/tmp/.local/lib/opencpn

# Copying DeepreyGui locale files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/locale
for mo_file in $DEEPREY_GUI_BUILD_DIR/*.mo; do
    locale_name=$(basename "$mo_file" .mo)
    target_dir="$DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/locale/${locale_name}/LC_MESSAGES"
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    cp -f "$mo_file" "$target_dir/opencpn-DeepreyGui_pi.mo"
done

# Copying DeepreyGui plugin files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/opencpn/plugins/DeepreyGui_pi
cp -r $DEEPREY_GUI_DIR/data $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/opencpn/plugins/DeepreyGui_pi

# Adding DeepreyRadar plugin files
cp $DEEPREY_RADAR_BUILD_DIR/libdeeprey-radar_pi.so $DEBIAN_PKG_SRC_FOLDER/tmp/.local/lib/opencpn

# Copying DeepreyRadar locale files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/locale
for mo_file in $DEEPREY_RADAR_BUILD_DIR/*.mo; do
    locale_name=$(basename "$mo_file" .mo)
    target_dir="$DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/locale/${locale_name}/LC_MESSAGES"
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    cp -f "$mo_file" "$target_dir/opencpn-deeprey-radar_pi.mo"
done

# Copying DeepreyRadar plugin files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/opencpn/plugins/deeprey-radar_pi
cp -r $DEEPREY_RADAR_DIR/data $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/opencpn/plugins/deeprey-radar_pi

# Adding DeepreySonar plugin files
cp $DEEPREY_SONAR_BUILD_DIR/libdeeprey-sonar_pi.so $DEBIAN_PKG_SRC_FOLDER/tmp/.local/lib/opencpn

# Copying DeepreySonar locale files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/locale
for mo_file in $DEEPREY_SONAR_BUILD_DIR/*.mo; do
    locale_name=$(basename "$mo_file" .mo)
    target_dir="$DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/locale/${locale_name}/LC_MESSAGES"
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    cp -f "$mo_file" "$target_dir/opencpn-deeprey-sonar_pi.mo"
done

# Copying DeepreySonar plugin files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/opencpn/plugins/deeprey-sonar_pi
cp -r $DEEPREY_SONAR_DIR/data $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/opencpn/plugins/deeprey-sonar_pi

# Adding DeepreyNavbar plugin files
cp $DEEPREY_NAVBAR_BUILD_DIR/libDeepreyNavBar_pi.so $DEBIAN_PKG_SRC_FOLDER/tmp/.local/lib/opencpn

# Copying DeepreyNavbar locale files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/locale
for mo_file in $DEEPREY_NAVBAR_BUILD_DIR/*.mo; do
    locale_name=$(basename "$mo_file" .mo)
    target_dir="$DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/locale/${locale_name}/LC_MESSAGES"
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    cp -f "$mo_file" "$target_dir/opencpn-DeepreyNavBar_pi.mo"
done

# Copying DeepreyNavbar plugin files
mkdir -p $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/opencpn/plugins/DeepreyNavBar_pi
cp -r $DEEPREY_NAVBAR_DIR/data $DEBIAN_PKG_SRC_FOLDER/tmp/.local/share/opencpn/plugins/DeepreyNavBar_pi


cd $DEBIAN_PKG_DIR

# Creating Debian Package
echo "Creating Debian package..."
dpkg --build $DEBIAN_PKG_SRC_FOLDER > "$LOG_DIR/dpkg_build.log" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Failed to create Debian package"
    exit 1
fi
echo "✅ Debian package created successfully"

# Rename the package to include the version
VERSION=$(git rev-parse --short HEAD)
PACKAGE_NAME="DeepreyPlugins_pi_${VERSION}_amd64.deb"
if [ -z "$VERSION" ]; then
    echo "❌ Failed to get version from git"
    exit 1
fi

rm -f "$PACKAGE_NAME" # Removing old package if it exists
if [ -f "$DEBIAN_PKG_SRC_FOLDER.deb" ]; then
    echo "Renaming package to $PACKAGE_NAME"
else
    echo "❌ $DEBIAN_PKG_SRC_FOLDER.deb not found, cannot rename package"
    exit 1
fi

mv $DEBIAN_PKG_SRC_FOLDER.deb "$IMAGE_SCRIPT_DIR/$PACKAGE_NAME"
cd $IMAGE_SCRIPT_DIR
chmod 777 "$PACKAGE_NAME" # Set permissions for the package
echo "Package created: $PACKAGE_NAME"
rm -rf custom_opencpn.deb
ln -s $PACKAGE_NAME custom_opencpn.deb

# Clean up OpenCPN default files before installing the plugin
cd $DEBIAN_PKG_DIR
./clean_opencpn.sh $1

cd $IMAGE_SCRIPT_DIR
# Install the plugin
dpkg -i "$PACKAGE_NAME" > "$LOG_DIR/dpkg_install.log" 2>&1
if [ $? -eq 0 ]; then
    echo "✅ OpenCPN installed successfully"
else
    echo "❌ OpenCPN failed"
fi

# Test OpenCPN
echo "Testing the OpenCPN..."
opencpn > "$LOG_DIR/opencpn.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✅ OpenCPN starts correctly"
else
    echo "❌ OpenCPN failed to start"
fi

cd $DEBIAN_PKG_DIR