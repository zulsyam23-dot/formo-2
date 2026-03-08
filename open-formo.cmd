@echo off
set SCRIPT_DIR=%~dp0
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\open_formo_workspace.ps1"
