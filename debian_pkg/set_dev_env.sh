echo "Installing OpenCPN build dependencies..."
cd $OPENCPN_DIR
mk-build-deps -ir ci/control
sudo apt-get -y --allow-unauthenticated install -f

echo "Installing DeepreyGui build dependencies..."
cd $DEEPREY_GUI_DIR
mk-build-deps -ir build-deps/control

echo "Installing DeepreyRadar build dependencies..."
cd $DEEPREY_RADAR_DIR
mk-build-deps -ir build-deps/control

cd $DEBIAN_PKG_DIR