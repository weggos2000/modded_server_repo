#!/usr/bin/env bash
# Homestead School - Performance aan (dubbelklik, of in een terminal: bash "Performance aan.command")
cd "$(dirname "$0")"
exec bash ./install.sh --set-mode performance --pause "$@"
