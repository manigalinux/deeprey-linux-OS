#!/bin/bash
cd deeprey
dpkg-scanpackages pool/ > dists/production/main/binary-amd64/Packages
gzip -c dists/production/main/binary-amd64/Packages > dists/production/main/binary-amd64/Packages.gz
echo -e "Origin: deeprey\nLabel: deeprey opencpn packages\nSuite: production\nCodename: production\nComponents: main\nArchitectures: amd64" > dists/production/Release
apt-ftparchive release dists/production >> dists/production/Release

# sign
export GNUPGHOME=../gpg-keys
rm -f dists/production/Release.gpg dists/production/InRelease
gpg --batch -abs -o dists/production/Release.gpg dists/production/Release
gpg --clearsign -o dists/production/InRelease dists/production/Release
