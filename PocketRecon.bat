@echo off
setlocal
chcp 65001 >nul
set "POCKETRECON_SCRIPT_DIR=%~dp0"
set "POCKETRECON_PS1=%~dp0PocketRecon.ps1"
if not exist "%POCKETRECON_PS1%" (
    echo [ERROR] PocketRecon.ps1 not found next to PocketRecon.bat
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%POCKETRECON_PS1%" %*
exit /b %ERRORLEVEL%
