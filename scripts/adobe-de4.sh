#!/bin/bash

set -euo pipefail


# Add 32 bit repos
dpkg --add-architecture i386

# Update the container and install packages
apt update
apt upgrade -y
grep -v '^#' ./adobe-de4.packages | xargs apt install -y

export WINEPREFIX=/opt/ade4_pfx
winetricks --force -q adobe_diged4

cat <<'EOF' | tee /usr/local/bin/ade4.sh
#!/bin/sh

export WINEPREFIX=/opt/ade4_pfx
wine "/opt/ade4_pfx/drive_c/Program Files (x86)/Adobe/Adobe Digital Editions 4.5"

EOF
chmod +x /usr/local/bin/ade4.sh

# Add distrobox shims
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/xdg-open


