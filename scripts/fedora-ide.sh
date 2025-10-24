#!/bin/bash

set -euo pipefail

# Update
dnf update -y

# Install packages
mapfile -t packages < <(grep -v '^#' /ctx/fedora-ide.packages)
if [ "${#packages[@]}" -gt 0 ]; then
	dnf install -y "${packages[@]}"
fi

# Clean up the cache to save on image size
dnf clean all

# Copy over jetbrains installer
#cp /ctx/modules/jetbrains/jetbrains-ide-setup.sh /usr/local/bin/jetbrains-ide-setup
