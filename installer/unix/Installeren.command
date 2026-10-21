#!/usr/bin/env bash
# Homestead School - Installeren (dubbelklik, of in een terminal: bash "Installeren.command")
cd "$(dirname "$0")"
exec bash ./install.sh --pause "$@"
