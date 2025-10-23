#!/bin/bash

set -euo pipefail

# Update
dnf update -y

# Install latest kubectl
dnf search 'kubernetes*-client' | grep -E 'kubernetes1\.[0-9]+-client' --only-matching | sort --version-sort | tail -n 1 | xargs dnf install -y

# Install packages
grep -v '^#' /ctx/fedora-dev.packages | xargs dnf install -y

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

# Copy over jetbrains installer
cp /ctx/modules/jetbrains/jetbrains-ide-setup.sh /usr/local/bin/jetbrains-ide-setup
