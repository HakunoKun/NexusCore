@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
set "ADB=%~dp0scrcpy-win64-v4.0\adb.exe"
set "API=%~dp0PocketServer\pocket_www\cgi-bin\api.sh"
title Updating Dashboard...
color 0B
echo ===========================================
echo       Forcing Update to Pocket WiFi
echo ===========================================
echo.

:: 1. ลบไฟล์เก่าทิ้ง
"%ADB%" shell "rm /data/local/tmp/www/cgi-bin/api.sh"

:: 2. ดันไฟล์ใหม่เข้าไป
echo [*] Pushing new script...
"%ADB%" push "%API%" /data/local/tmp/www/cgi-bin/api.sh

:: 3. แปลงบรรทัดแบบ Linux และตั้งสิทธิ์
echo [*] Formatting...
"%ADB%" shell "/data/local/tmp/busybox dos2unix /data/local/tmp/www/cgi-bin/api.sh 2>/dev/null"
"%ADB%" shell "chmod 777 /data/local/tmp/www/cgi-bin/api.sh"

echo.
echo [OK] Update Complete!
echo You can now refresh your browser at http://192.168.100.1:9000
echo.
pause
