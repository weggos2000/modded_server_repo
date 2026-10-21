#!/usr/bin/env bash
# Homestead School - Performance uit (dubbelklik, of in een terminal: bash "Performance uit.sh")
cd "$(dirname "$0")"
exec bash ./install.sh --set-mode normal --pause "$@"
