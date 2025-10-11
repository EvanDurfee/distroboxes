#!/bin/bash

set -euo pipefail

# Update
dnf update -y

# Add rpm fusion
dnf install -y \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf config-manager setopt fedora-cisco-openh264.enabled=1

dnf update -y

# Install ffmpeg
dnf swap ffmpeg-free ffmpeg --allowerasing -y
# dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
# Install intel and amd drivers
dnf install -y intel-media-driver
dnf swap mesa-va-drivers mesa-va-drivers-freeworld
dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
