#!/bin/bash

set -euo pipefail

# Update
dnf update -y

# Install latest kubectl
dnf search 'kubernetes*-client' | grep -E 'kubernetes1\.[0-9]+-client' --only-matching | sort --version-sort | tail -n 1 | xargs dnf install -y

# Install packages
grep -v '^#' ./fedora-dev.packages | xargs dnf install -y

# Install python and pip
# python_versions=(python3.6 python3.9 python3.10 python3.11 python3.12 python3.13 python3.14)
python_versions=($(dnf search 'python3.*' | grep --perl-regexp 'python3\.[1-9][0-9]?' --only-matching | sort --version-sort --unique))
dnf install -y "${python_versions[@]}"
for python_version in "${python_versions[@]}"; do
	echo "Install pip for $python_version"
	"$python_version" -m ensurepip
done

# Clean up the cache to save on image size
dnf clean all

# Add distrobox shims
# mkdir -p /run/dbus
# ln -fs /run/host/run/dbus/system_bus_socket /run/dbus
# ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/xdg-open
#[ ! -e /usr/bin/sh ] && ln -fs /bin/sh /usr/bin/sh
# mkdir -p /run/dbus
# ln -fs /run/host/run/dbus/system_bus_socket /run/dbus
# ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/docker
# ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/flatpak
# ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman
# ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree
# ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/ostree
# ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/bootc
# ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/transactional-update
# ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/xdg-open
