@echo off
cd %~dp0
powershell.exe -ExecutionPolicy Bypass -NoProfile ".\src\install.ps1"
