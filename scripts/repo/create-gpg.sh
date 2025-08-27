#!/bin/bash
mkdir -p gpg-keys
chmod 700 gpg-keys
export GNUPGHOME=gpg-keys

gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 4096
Name-Real: Deeprey Debian Repo
Name-Email: repo@example.com
Expire-Date: 0
%no-protection
%commit
EOF

gpg --export -a "repo@example.com" > ${GNUPGHOME}/repo-public.key
gpg --export -a "repo@example.com" > deeprey/deeprey.key
