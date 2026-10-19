@echo off
title Homestead School - performance uit
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -SetMode normal %*
