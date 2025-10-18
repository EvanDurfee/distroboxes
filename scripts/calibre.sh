#!/bin/bash

set -euo pipefail

# Update the container and install packages
dnf update -y
grep -v '^#' ./calibre.packages | xargs dnf install -y

# Clean the cache
dnf clean all

# Add distrobox shims
# ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/xdg-open
