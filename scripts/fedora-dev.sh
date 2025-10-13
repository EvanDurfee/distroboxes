#!/bin/bash

set -euo pipefail

# Update
dnf update -y

# Install latest kubectl
dnf search 'kubernetes*-client' | grep -E 'kubernetes1\.[0-9]+-client' --only-matching | sort --version-sort | tail -n 1 | xargs dnf install -y

# Install packages
grep -v '^#' ./fedora-dev.packages | xargs dnf install -y

# Add distrobox shims
mkdir -p /run/dbus
ln -fs /run/host/run/dbus/system_bus_socket /run/dbus
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/xdg-open

[ ! -e /usr/bin/sh ] && ln -fs /bin/sh /usr/bin/sh
# mkdir -p /run/dbus
# ln -fs /run/host/run/dbus/system_bus_socket /run/dbus
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/docker
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/flatpak
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/ostree
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/bootc
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/transactional-update
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/xdg-open
