#!/bin/bash

set -euo pipefail


# Add 32 bit repos
dpkg --add-architecture i386

# Update the container and install packages
apt update
apt upgrade -y
grep -v '^#' ./adobe-de4.packages | xargs apt install -y

export WINEPREFIX=~/.adewine
winetricks --force -q adobe_diged4

# Add distrobox shims
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/xdg-open


