$ErrorActionPreference = "SilentlyContinue"
$scriptRoot = $env:POCKETRECON_SCRIPT_DIR
if ([string]::IsNullOrWhiteSpace($scriptRoot)) { $scriptRoot = $PSScriptRoot }
if ([string]::IsNullOrWhiteSpace($scriptRoot)) { $scriptRoot = (Get-Location).Path }
$scriptRoot = $scriptRoot.TrimEnd('\')
$target    = "192.168.100.66"
$adb       = Join-Path $scriptRoot "scrcpy-win64-v4.0\adb.exe"
$outFile   = Join-Path $scriptRoot "PocketRecon_Result.txt"
$bw        = 60

# ══════════════════════════════════════════════════════════
#  UI HELPERS
# ══════════════════════════════════════════════════════════
function Log { param([string]$M) $M | Out-File $outFile -Append -Encoding UTF8 }

function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║   PocketRecon v2.0  —  M32-5 ADB Exploit Kit            ║" -ForegroundColor White
    Write-Host "  ║   Target: $target  |  ADB Auto-Detect             ║" -ForegroundColor DarkGray
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section { param([string]$T, [string]$Color = "Yellow")
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────┐" -ForegroundColor $Color
    Write-Host "  │  $($T.PadRight(55))│" -ForegroundColor $Color
    Write-Host "  └─────────────────────────────────────────────────────────┘" -ForegroundColor $Color
    Log "`n══ $T ══"
}

function Write-Ok  { param([string]$M) Write-Host "  [+] $M" -ForegroundColor Green;  Log "[+] $M" }
function Write-Err { param([string]$M) Write-Host "  [-] $M" -ForegroundColor Red;    Log "[-] $M" }
function Write-Inf { param([string]$M) Write-Host "  [*] $M" -ForegroundColor Cyan;   Log "[*] $M" }
function Write-Wrn { param([string]$M) Write-Host "  [!] $M" -ForegroundColor Yellow; Log "[!] $M" }

function Show-Menu {
    param ([string[]]$Options, [string]$Title)
    Write-Host ""
    Write-Host "  ╭─── $Title $('─' * [Math]::Max(1, 50 - $Title.Length))╮" -ForegroundColor DarkCyan
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  │  [$($i+1)] $($Options[$i])" -ForegroundColor Gray
    }
    Write-Host "  │  [0] Back / Exit" -ForegroundColor DarkGray
    Write-Host "  ╰$('─' * 56)╯" -ForegroundColor DarkCyan
    Write-Host ""
    $sel = Read-Host "  ► Select"
    return $sel
}

# ══════════════════════════════════════════════════════════
#  ADB HELPERS
# ══════════════════════════════════════════════════════════
function Get-AdbDevice {
    $devices = & $adb devices 2>$null | Select-Object -Skip 1 | Where-Object { $_ -match "device\s*$" }
    if ($devices) { return ($devices -split "\s+")[0] }
    return $null
}

function Invoke-AdbShell { param([string]$Cmd)
    return & $adb shell $Cmd 2>&1
}

function Check-Root {
    $id = Invoke-AdbShell "id"
    return $id -match "uid=0"
}

# ══════════════════════════════════════════════════════════
#  MODULE 1: NETWORK SCAN (WiFi Mode)
# ══════════════════════════════════════════════════════════
function Run-NetworkScan {
    Write-Section "MODULE 1: NETWORK SCAN (WiFi Mode)" "Yellow"

    # Connectivity check
    $adapter = Get-NetIPConfiguration | Where-Object { $_.IPv4Address.IPAddress -match "192.168.100" }
    if (-not $adapter) {
        Write-Wrn "Not on 192.168.100.x subnet. Target $target might be unreachable!"
    } else {
        Write-Ok "Interface: $($adapter.InterfaceAlias) / Your IP: $($adapter.IPv4Address.IPAddress)"
    }

    # Ping
    Write-Inf "Pinging $target..."
    $ping = Test-Connection $target -Count 2 -EA SilentlyContinue
    if ($ping) {
        Write-Ok "Ping OK — $($ping[0].ResponseTime)ms TTL=$($ping[0].TimeToLive)"
    } else { Write-Err "No ping response" }

    # Port scan
    Write-Inf "Scanning ports..."
    $ports = @(21,22,23,53,80,443,1080,3000,5555,7547,8000,8080,8443,9000,22345)
    $open = @()
    foreach ($p in $ports) {
        $tcp = New-Object System.Net.Sockets.TcpClient
        try {
            if ($tcp.ConnectAsync($target, $p).Wait(400) -and $tcp.Connected) {
                $open += $p
                $name = @{21="FTP";22="SSH";23="Telnet";53="DNS";80="HTTP";443="HTTPS";5555="ADB";7547="TR-069";8000="HiMi API";8080="HTTP-Proxy";22345="Unknown"}[$p]
                Write-Ok "Port $p OPEN — $name"
            }
        } catch {} finally { $tcp.Close() }
    }
    if ($open.Count -eq 0) { Write-Wrn "No interesting ports found" }

    # HTTP Probe
    Write-Inf "Probing HTTP endpoints..."
    $urls = @(
        "http://$target/",
        "http://$target:8000/",
        "http://$target:8000/login",
        "http://$target:8000/api/v1/device",
        "http://$target:8000/api/v1/network",
        "http://$target:8000/api/v1/apn",
        "http://$target:8000/api/v1/sim",
        "http://$target:8000/api/v1/status"
    )
    foreach ($url in $urls) {
        try {
            $r = Invoke-WebRequest -Uri $url -TimeoutSec 3 -UseBasicParsing
            $snippet = ($r.Content -replace '\s+',' ').Substring(0, [Math]::Min(120, $r.Content.Length))
            Write-Ok "HIT $($r.StatusCode): $url"
            Write-Inf "  Content: $snippet"
            Log "  Full: $($r.Content.Substring(0,[Math]::Min(500,$r.Content.Length)))"
        } catch {
            $code = [int]$_.Exception.Response.StatusCode.Value__
            if ($code -and $code -ne 404) { Write-Wrn "HTTP $code : $url" }
        }
    }

    # MAC
    $arpLine = (arp -a | Select-String $target)
    if ($arpLine -match "([0-9a-f]{2}[:-]){5}[0-9a-f]{2}") {
        Write-Ok "MAC Address: $($matches[0])"
        Write-Wrn "  → Lookup MAC prefix at macvendors.com to find chipset"
    }

    Log "Open ports: $($open -join ', ')"
    Write-Ok "Network scan complete — results saved to PocketRecon_Result.txt"
}

# ══════════════════════════════════════════════════════════
#  MODULE 2: ADB CONNECT + DEVICE INFO
# ══════════════════════════════════════════════════════════
function Run-AdbConnect {
    Write-Section "MODULE 2: ADB DEVICE CONNECT + FINGERPRINT" "Cyan"

    Write-Inf "Starting ADB server..."
    & $adb start-server 2>$null
    Start-Sleep 2

    $dev = Get-AdbDevice
    if (-not $dev) {
        Write-Wrn "No ADB device found via USB — trying TCP connect..."
        & $adb connect "$target`:5555" 2>$null
        Start-Sleep 2
        $dev = Get-AdbDevice
    }

    if (-not $dev) {
        Write-Err "ADB device not found! Plug USB cable into Pocket WiFi."
        Write-Inf "Also check: Settings → About → Enable USB Debugging"
        return $false
    }
    Write-Ok "ADB connected: $dev"

    # Device fingerprint
    Write-Inf "Collecting device info..."
    $props = @{
        "OS Version"   = Invoke-AdbShell "getprop ro.build.version.release"
        "Build Type"   = Invoke-AdbShell "getprop ro.build.type"
        "Build Keys"   = Invoke-AdbShell "getprop ro.build.tags"
        "Model"        = Invoke-AdbShell "getprop ro.product.model"
        "Board"        = Invoke-AdbShell "getprop ro.product.board"
        "Hardware"     = Invoke-AdbShell "getprop ro.hardware"
        "SDK"          = Invoke-AdbShell "getprop ro.build.version.sdk"
        "Display ID"   = Invoke-AdbShell "getprop ro.build.display.id"
        "SIM State"    = Invoke-AdbShell "getprop gsm.sim.state"
        "Operator"     = Invoke-AdbShell "getprop gsm.operator.alpha"
        "Network MCC"  = Invoke-AdbShell "getprop gsm.operator.numeric"
    }
    foreach ($k in $props.Keys) {
        $v = $props[$k]
        if ($v) { Write-Ok "${k}: $v" }
    }

    # RAM & Storage
    $mem = Invoke-AdbShell "cat /proc/meminfo" | Select-Object -First 2
    Write-Ok "RAM: $($mem[0]) / Free: $($mem[1])"
    $df = Invoke-AdbShell "df /data"
    Write-Ok "Storage: $df"

    # Running processes (interesting ones)
    Write-Inf "Interesting processes..."
    $ps = Invoke-AdbShell "ps" | Select-String "himi|rild|netd|dnsmasq|hostapd"
    $ps | ForEach-Object { Write-Ok "  Process: $_" }

    # Open ports from inside
    Write-Inf "Internal port map..."
    $netstat = Invoke-AdbShell "netstat -tlnp"
    $netstat | ForEach-Object { if ($_ -match "LISTEN") { Write-Ok "  $_" } }

    Log "ADB fingerprint complete"
    return $true
}

# ══════════════════════════════════════════════════════════
#  MODULE 3: ROOT EXPLOIT ATTEMPT
# ══════════════════════════════════════════════════════════
function Run-RootExploit {
    Write-Section "MODULE 3: ROOT EXPLOIT ATTEMPT" "Magenta"

    # Check if already root
    if (Check-Root) {
        Write-Ok "Already running as ROOT! uid=0"
        return $true
    }
    Write-Inf "Current user: $(Invoke-AdbShell 'id')"

    # Method 1: adb root (userdebug build)
    Write-Inf "Method 1: adb root (userdebug exploit)..."
    & $adb root 2>$null
    Start-Sleep 3
    & $adb wait-for-device 2>$null
    Start-Sleep 2

    if (Check-Root) {
        Write-Ok "ROOT SUCCESS via userdebug! uid=0"
        Log "Root method: userdebug adb root"
        return $true
    }
    Write-Wrn "Method 1 failed — trying Method 2"

    # Method 2: setprop service.adb.root
    Write-Inf "Method 2: setprop service.adb.root=1..."
    Invoke-AdbShell "setprop service.adb.root 1" | Out-Null
    Invoke-AdbShell "setprop ctl.restart adbd" | Out-Null
    Start-Sleep 3

    if (Check-Root) {
        Write-Ok "ROOT SUCCESS via setprop!"
        Log "Root method: setprop service.adb.root"
        return $true
    }
    Write-Wrn "Method 2 failed — trying Method 3"

    # Method 3: writable /system check
    Write-Inf "Method 3: Check writable /system..."
    & $adb remount 2>$null
    $testWrite = Invoke-AdbShell "echo test > /system/test_rw.tmp && cat /system/test_rw.tmp"
    if ($testWrite -match "test") {
        Invoke-AdbShell "rm /system/test_rw.tmp" | Out-Null
        Write-Ok "/system is WRITABLE — partial root access!"
        Log "Root method: remount writable /system"
        return $true
    }

    Write-Err "All root methods failed — device may have locked bootloader"
    Write-Wrn "Continuing with shell (uid=2000) permissions..."
    return $false
}

# ══════════════════════════════════════════════════════════
#  MODULE 4: APN FIX via ADB
# ══════════════════════════════════════════════════════════
function Run-ApnFix {
    Write-Section "MODULE 4: APN CONFIG FIX (TRUE SIM)" "Green"

    $isRoot = Check-Root
    if (-not $isRoot) {
        Write-Wrn "Not root — APN via Activity Manager (limited)"
        # Try via am broadcast intent
        Write-Inf "Trying APN fix via broadcast intent..."
        Invoke-AdbShell "am broadcast -a android.intent.action.APN_CHANGED" | Out-Null
    } else {
        Write-Inf "Root available — writing APN directly via content provider..."
        $apnCmd = @"
content insert --uri content://telephony/carriers
  --bind name:s:TRUE
  --bind mcc:s:520
  --bind mnc:s:04
  --bind apn:s:internet
  --bind user:s:true
  --bind password:s:true
  --bind authtype:i:1
  --bind type:s:default,supl,mms
  --bind current:i:1
"@
        $result = Invoke-AdbShell (($apnCmd -replace '\r?\n',' ').Trim())
        if ($result -match "result") {
            Write-Ok "APN inserted successfully!"
        } else {
            Write-Wrn "Direct insert may have failed — trying via settings DB..."
            # Try sqlite3
            $sqlite = Invoke-AdbShell "sqlite3 /data/data/com.android.providers.telephony/databases/telephony.db 'INSERT INTO carriers (name,mcc,mnc,apn,user,password,authtype,type,current) VALUES (\"TRUE\",\"520\",\"04\",\"internet\",\"true\",\"true\",1,\"default\",1);'"
            if ($sqlite -notmatch "error") {
                Write-Ok "APN inserted via SQLite!"
            } else {
                Write-Err "SQLite insert failed: $sqlite"
            }
        }
    }

    # Also try setprop for immediate effect
    Write-Inf "Pushing network restart..."
    Invoke-AdbShell "setprop net.gprs.local-ip ''" | Out-Null
    Invoke-AdbShell "setprop ctl.restart ril-daemon" | Out-Null
    Start-Sleep 2

    # Check SIM state
    $simState = Invoke-AdbShell "getprop gsm.sim.state"
    $operator = Invoke-AdbShell "getprop gsm.operator.alpha"
    $numeric  = Invoke-AdbShell "getprop gsm.operator.numeric"
    Write-Inf "SIM State: $simState"
    Write-Inf "Operator: $operator ($numeric)"

    if ($simState -match "READY") {
        Write-Ok "SIM is READY — APN fix should take effect!"
    } elseif ($simState -match "ABSENT") {
        Write-Err "SIM not detected inside device — check physical SIM insertion!"
    } else {
        Write-Wrn "SIM State: $simState — may still be connecting..."
    }
}

# ══════════════════════════════════════════════════════════
#  MODULE 5: PERSISTENCE + MINI SERVER DEPLOY
# ══════════════════════════════════════════════════════════
function Run-ServerDeploy {
    Write-Section "MODULE 5: DYNAMIC SERVER DEPLOY (Port 9000)" "Green"

    $isRoot = Check-Root
    if (-not $isRoot) {
        Write-Wrn "Not root — deploying in user space (/data/local/tmp)"
    }

    $targetDir = "/data/local/tmp"
    $serverDir = Join-Path $scriptRoot "PocketServer"

    if (-not (Test-Path "$serverDir\busybox-arm")) {
        Write-Err "busybox-arm not found in $serverDir!"
        return
    }

    Write-Inf "Pushing BusyBox to device..."
    & $adb push "$serverDir\busybox-arm" "$targetDir/busybox" 2>$null
    Invoke-AdbShell "chmod 777 $targetDir/busybox" | Out-Null

    Write-Inf "Pushing Web Dashboard files..."
    Invoke-AdbShell "rm -r $targetDir/www 2>/dev/null" | Out-Null
    Invoke-AdbShell "mkdir -p $targetDir/www/cgi-bin" | Out-Null
    
    & $adb push "$serverDir\pocket_www\index.html" "$targetDir/www/index.html" 2>$null
    & $adb push "$serverDir\pocket_www\cgi-bin\api.sh" "$targetDir/www/cgi-bin/api.sh" 2>$null
    Invoke-AdbShell "$targetDir/busybox dos2unix $targetDir/www/cgi-bin/api.sh 2>/dev/null" | Out-Null
    Invoke-AdbShell "chmod 777 $targetDir/www/cgi-bin/api.sh" | Out-Null

    Write-Inf "Starting Web Server on port 9000..."
    Invoke-AdbShell "killall busybox 2>/dev/null" | Out-Null
    Invoke-AdbShell "$targetDir/busybox httpd -p 9000 -h $targetDir/www" | Out-Null

    Write-Ok "Server deployed and running in background!"
    Write-Ok "Access Dashboard at: http://$target:9000"
}

# ══════════════════════════════════════════════════════════
#  MODULE 6: FULL DEVICE DUMP (Forensics)
# ══════════════════════════════════════════════════════════
function Run-DeviceDump {
    Write-Section "MODULE 6: FULL DEVICE DUMP" "DarkYellow"

    $dumpDir = Join-Path $scriptRoot "PocketDump_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $dumpDir -Force | Out-Null
    Write-Ok "Dump directory: $dumpDir"

    # Pull all props
    Write-Inf "Dumping all system properties..."
    Invoke-AdbShell "getprop" | Out-File "$dumpDir\getprop.txt"
    Write-Ok "getprop.txt saved"

    # Pull system app list
    Write-Inf "Dumping installed packages..."
    Invoke-AdbShell "pm list packages -f" | Out-File "$dumpDir\packages.txt"
    Write-Ok "packages.txt saved"

    # Pull himiwebserver binary (web UI)
    Write-Inf "Pulling himiwebserver binary..."
    & $adb pull /system/bin/himiwebserver "$dumpDir\himiwebserver" 2>$null
    Write-Ok "himiwebserver saved ($('{0:N0}' -f (Get-Item "$dumpDir\himiwebserver" -EA SilentlyContinue).Length) bytes)"

    # Pull init scripts
    Write-Inf "Pulling init scripts..."
    & $adb pull /init.rc "$dumpDir\init.rc" 2>$null
    Write-Ok "init.rc saved"

    # Pull logcat
    Write-Inf "Pulling device logs..."
    & $adb logcat -d | Out-File "$dumpDir\logcat.txt"
    Write-Ok "logcat.txt saved"

    # Screenshot
    Write-Inf "Taking screenshot..."
    Invoke-AdbShell "screencap -p /sdcard/recon_screen.png" | Out-Null
    & $adb pull /sdcard/recon_screen.png "$dumpDir\screen.png" 2>$null
    Write-Ok "screen.png saved"

    # Extract strings from himiwebserver for API endpoints
    Write-Inf "Extracting API endpoints from binary..."
    if (Test-Path "$dumpDir\himiwebserver") {
        $bytes = [System.IO.File]::ReadAllBytes("$dumpDir\himiwebserver")
        $str = [System.Text.Encoding]::ASCII.GetString($bytes)
        $apiPaths = $str -split '[^\x20-\x7E]+' | Where-Object {
            $_ -match '^(/[a-zA-Z0-9_/\-]+){1,5}$' -and $_.Length -gt 4 -and $_.Length -lt 60
        } | Select-Object -Unique | Sort-Object
        $apiPaths | Out-File "$dumpDir\api_endpoints.txt"
        Write-Ok "Found $($apiPaths.Count) potential API endpoints → api_endpoints.txt"
        $apiPaths | Select-Object -First 10 | ForEach-Object { Write-Inf "  $_" }
    }

    Write-Ok "Full dump saved to: $dumpDir"
    Log "Device dump: $dumpDir"
}

# ══════════════════════════════════════════════════════════
#  MAIN MENU
# ══════════════════════════════════════════════════════════
if (Test-Path $outFile) { Remove-Item $outFile -Force }
Log "PocketRecon v2.0 — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Log "Target: $target"

while ($true) {
    Write-Header

    $choice = Show-Menu -Title "MAIN MENU — M32-5 Exploit Kit" -Options @(
        "Network Scan        — Port scan + HTTP probe (WiFi mode)",
        "ADB Connect         — Detect device + full fingerprint",
        "Root Exploit        — Try userdebug root methods",
        "APN Fix (TRUE SIM)  — Auto-configure APN via ADB",
        "Server Deploy       — Push shell listener + server scripts",
        "Full Device Dump    — Save logs, binary, API endpoints"
    )

    switch ($choice) {
        "1" { Run-NetworkScan }
        "2" { Run-AdbConnect }
        "3" { Run-RootExploit }
        "4" { Run-ApnFix }
        "5" { Run-ServerDeploy }
        "6" { Run-DeviceDump }
        "0" {
            Clear-Host
            Write-Host ""
            Write-Host "  PocketRecon terminated." -ForegroundColor DarkGray
            Write-Host "  Results saved to: $outFile" -ForegroundColor DarkGray
            Write-Host ""
            exit
        }
        default { Write-Wrn "Invalid selection" }
    }

    Write-Host ""
    Write-Host "  Press any key to return to menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
