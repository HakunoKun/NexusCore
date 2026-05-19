@echo off
setlocal
chcp 65001 >nul
set "PHONEBOX_SCRIPT_DIR=%~dp0"
set "PHONEBOX_PS1=%~dp0PhoneBox.ps1"
if not exist "%PHONEBOX_PS1%" (
    echo [ERROR] PhoneBox.ps1 not found next to PhoneBox.bat
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PHONEBOX_PS1%" %*
exit /b %ERRORLEVEL%
