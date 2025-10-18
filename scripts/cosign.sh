#!/bin/bash

set -euo pipefail

# Update the container and install packages
grep -v '^#' ./cosign.packages | xargs apk add --no-cache

