@echo off
rem Starts the Skin Swapper window. This black window is the log.
title Skin Swapper - Log
cd /d "%~dp0"
powershell -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0SkinSwapper.ps1"
echo.
echo Press any key to close this log window.
pause >nul
