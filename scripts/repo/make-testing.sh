#!/bin/bash
cd deeprey
dpkg-scanpackages pool/ > dists/testing/main/binary-amd64/Packages
gzip -c dists/testing/main/binary-amd64/Packages > dists/testing/main/binary-amd64/Packages.gz
echo -e "Origin: deeprey\nLabel: deeprey opencpn packages\nSuite: testing\nCodename: testing\nComponents: main\nArchitectures: amd64" > dists/testing/Release
apt-ftparchive release dists/testing >> dists/testing/Release

# sign
export GNUPGHOME=../gpg-keys
rm dists/testing/Release.gpg dists/testing/InRelease
gpg --batch -abs -o dists/testing/Release.gpg dists/testing/Release
gpg --clearsign -o dists/testing/InRelease dists/testing/Release
