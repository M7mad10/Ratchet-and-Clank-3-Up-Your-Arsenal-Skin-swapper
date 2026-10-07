@echo off
rem Starts the Skin Swapper 2.0 window. This black window is the log.
title Skin Swapper 2.0 - Log
cd /d "%~dp0"
powershell -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0SkinSwapper2.ps1"
echo.
echo Press any key to close this log window.
pause >nul
