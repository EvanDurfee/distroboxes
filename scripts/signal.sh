#!/bin/bash

set -euo pipefail

# Add signal repo
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
wget -O signal-desktop.sources https://updates.signal.org/static/desktop/apt/signal-desktop.sources
cat signal-desktop.sources | sudo tee /etc/apt/sources.list.d/signal-desktop.sources > /dev/null
rm signal-desktop.sources signal-desktop-keyring.gpg

# Update the container and install packages
apt update
apt upgrade -y
grep -v '^#' ./signal.packages | xargs apt install -y

# Add distrobox shims
mkdir -p /run/dbus
ln -fs /run/host/run/dbus/system_bus_socket /run/dbus
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/xdg-open
