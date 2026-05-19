$ErrorActionPreference = "SilentlyContinue"
$scriptRoot = $env:PHONEBOX_SCRIPT_DIR
if ([string]::IsNullOrWhiteSpace($scriptRoot)) { $scriptRoot = $PSScriptRoot }
if ([string]::IsNullOrWhiteSpace($scriptRoot)) { $scriptRoot = (Get-Location).Path }
$scriptRoot = $scriptRoot.TrimEnd('\')
$scrcpyPath = Join-Path $scriptRoot "scrcpy-win64-v4.0"
$bw = 58

# ──────────────────────────────────────────────────────────
#  UI HELPERS
# ──────────────────────────────────────────────────────────

function Write-BoxLine {
    param ([string]$Text, [string]$FG = "Gray", [string]$BG = "", [switch]$Highlight)
    # Truncate if over box width to prevent wrap
    if ($Text.Length -gt $bw) { $Text = $Text.Substring(0, $bw - 1) + "~" }
    Write-Host "  │" -NoNewline -ForegroundColor DarkGray
    if ($Highlight) {
        Write-Host $Text.PadRight($bw) -NoNewline -ForegroundColor Black -BackgroundColor Cyan
    } elseif ($BG) {
        Write-Host $Text.PadRight($bw) -NoNewline -ForegroundColor $FG -BackgroundColor $BG
    } else {
        Write-Host $Text.PadRight($bw) -NoNewline -ForegroundColor $FG
    }
    Write-Host "│" -ForegroundColor DarkGray
}

function Write-EmptyBoxLine {
    param ([string]$BorderColor = "DarkGray")
    Write-Host "  │" -NoNewline -ForegroundColor $BorderColor
    Write-Host (" " * $bw) -NoNewline
    Write-Host "│" -ForegroundColor $BorderColor
}

function Write-PanelLine {
    # Bordered row using a custom border color (for colored panels)
    param ([string]$Text, [string]$FG = "Gray", [string]$BorderColor = "Green")
    if ($Text.Length -gt $bw) { $Text = $Text.Substring(0, $bw - 1) + "~" }
    Write-Host "  ║" -NoNewline -ForegroundColor $BorderColor
    Write-Host $Text.PadRight($bw) -NoNewline -ForegroundColor $FG
    Write-Host "║" -ForegroundColor $BorderColor
}

# ──────────────────────────────────────────────────────────
#  BANNER
# ──────────────────────────────────────────────────────────

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host "                                                          " -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host "   ____  _                      ____                  " -NoNewline -ForegroundColor White
    Write-Host "    ║" -ForegroundColor Cyan
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host "  |  _ \| _ _   ___  _ __   ___| __ )  _____  __      " -NoNewline -ForegroundColor White
    Write-Host "    ║" -ForegroundColor Cyan
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host "  | |_) | '_ \ / _ \| '_ \ / _ \  _ \ / _ \ \/ /      " -NoNewline -ForegroundColor White
    Write-Host "    ║" -ForegroundColor Cyan
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host "  |  __/| | | | (_) | | | |  __/ |_) | (_) >  <       " -NoNewline -ForegroundColor White
    Write-Host "    ║" -ForegroundColor Cyan
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host "  |_|   |_| |_|\___/|_| |_|\___|____/ \___/_/\_\      " -NoNewline -ForegroundColor White
    Write-Host "    ║" -ForegroundColor Cyan
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host "                                                          " -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host "       Smart Wireless Device Manager  " -NoNewline -ForegroundColor DarkCyan
    Write-Host "        v4.1        " -NoNewline -ForegroundColor DarkGray
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

# ──────────────────────────────────────────────────────────
#  STATUS BAR
# ──────────────────────────────────────────────────────────

function Write-StatusBar {
    param ([int]$DeviceCount, [int]$UsbCount, [int]$WifiCount)
    $timeStr = (Get-Date).ToString("HH:mm:ss")
    Write-Host ""
    Write-Host "  ┌──────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "  │" -NoNewline -ForegroundColor DarkGray
    $left  = "  Devices: $DeviceCount  [USB: $UsbCount]  [WiFi: $WifiCount]"
    $right = "$timeStr  "
    $pad   = $bw - $left.Length - $right.Length
    if ($pad -lt 0) { $pad = 1 }
    Write-Host ($left + (" " * $pad) + $right).PadRight($bw) -NoNewline -ForegroundColor DarkYellow
    Write-Host "│" -ForegroundColor DarkGray
    Write-Host "  └──────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
}

# ──────────────────────────────────────────────────────────
#  MAIN MENU
# ──────────────────────────────────────────────────────────

function Show-Menu {
    param ($IPs, $SelectedIndex)

    Write-Banner

    # Count by type for status bar
    $usbCount  = ($IPs | Where-Object { $_ -match "\|ADB_USB\|" }).Count
    $wifiCount = ($IPs | Where-Object { $_ -match "\|ADB_NET\||\|READY\|" }).Count
    Write-StatusBar -DeviceCount $IPs.Count -UsbCount $usbCount -WifiCount $wifiCount

    Write-Host ""
    Write-Host "    ↑↓  Navigate    ENTER  Connect    " -NoNewline -ForegroundColor DarkGray
    Write-Host "ESC  Exit" -ForegroundColor DarkRed
    Write-Host ""

    Write-Host "  ╭──────────────────── DETECTED DEVICES ─────────────────────╮" -ForegroundColor DarkGray
    Write-EmptyBoxLine

    if ($IPs.Count -eq 0) {
        Write-BoxLine "        (No devices found)" "DarkRed"
    } else {
        for ($i = 0; $i -lt $IPs.Count; $i++) {
            $parts   = $IPs[$i] -split "\|"
            $serial  = $parts[0]
            $model   = if ($parts[1] -and $parts[1].Trim()) { $parts[1].Trim() } else { "Android Device" }
            $status  = if ($parts[2]) { $parts[2] } else { "OTHER" }
            $ip      = if ($parts.Count -gt 3) { $parts[3] } else { "" }
            $portFlg = if ($parts.Count -gt 4) { $parts[4] } else { "" }

            switch ($status) {
                "ADB_USB" {
                    $badge  = "[USB] "
                    $clr    = "Cyan"
                    $ipPart = if ($ip -and $ip -ne "No WiFi") { " | WiFi: $ip" } else { " | No WiFi" }
                    # Show port 5555 state hint
                    $p5hint = if ($portFlg -eq "5555_OPEN") { " [5555:OK]" } elseif ($portFlg -eq "5555_CLOSED") { " [5555:--]" } else { "" }
                    $label  = "$badge$model$ipPart$p5hint"
                }
                "ADB_NET" {
                    $badge  = "[WiFi]"
                    $clr    = "Green"
                    $label  = "$badge $model | $ip"
                }
                "READY" {
                    $badge  = "[WiFi]"
                    $clr    = "Yellow"
                    $label  = "$badge Android Device | $ip  (port 5555 open)"
                }
                default {
                    $badge  = "[ -- ]"
                    $clr    = "DarkGray"
                    $label  = "$badge Unknown | $ip"
                }
            }

            $num  = ($i + 1).ToString().PadLeft(2)
            $line = "  $num. $label"
            if ($i -eq $SelectedIndex) {
                Write-BoxLine " ►$line" -Highlight
            } else {
                Write-BoxLine "   $line" $clr
            }
        }
    }

    Write-EmptyBoxLine
    Write-Host "  ├──────────────────── QUICK  ACTIONS ──────────────────────┤" -ForegroundColor DarkGray
    Write-EmptyBoxLine

    if ($SelectedIndex -eq $IPs.Count) {
        Write-BoxLine "   ►  A.  Enter IP Manually" -Highlight
    } else {
        Write-BoxLine "      A.  Enter IP Manually" "Gray"
    }

    if ($SelectedIndex -eq ($IPs.Count + 1)) {
        Write-BoxLine "   ►  B.  Rescan Network" -Highlight
    } else {
        Write-BoxLine "      B.  Rescan Network" "Gray"
    }

    Write-EmptyBoxLine
    Write-Host "  ╰──────────────────────────────────────────────────────────╯" -ForegroundColor DarkGray
}

# ──────────────────────────────────────────────────────────
#  SCAN ANIMATION 
# ──────────────────────────────────────────────────────────

function Show-ScanAnimation {
    Write-Banner
    Write-Host ""
    Write-Host "  ╭──────────────────────────────────────────────────────────╮" -ForegroundColor Yellow
    Write-EmptyBoxLine "Yellow"
    Write-Host "  │" -NoNewline -ForegroundColor Yellow
    Write-Host "     Scanning for ADB & Network Devices...                " -NoNewline -ForegroundColor White
    Write-Host "│" -ForegroundColor Yellow
    Write-Host "  │" -NoNewline -ForegroundColor Yellow
    Write-Host "     [ USB  ] Checking adb devices...                     " -NoNewline -ForegroundColor Cyan
    Write-Host "│" -ForegroundColor Yellow
    Write-Host "  │" -NoNewline -ForegroundColor Yellow
    Write-Host "     [ WiFi ] Probing ARP table on port 5555...           " -NoNewline -ForegroundColor Green
    Write-Host "│" -ForegroundColor Yellow
    Write-EmptyBoxLine "Yellow"
    Write-Host "  ╰──────────────────────────────────────────────────────────╯" -ForegroundColor Yellow
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  BUG FIX: Show-ConnectPanel now reflects actual conn type
#  and shows device model name correctly
# ──────────────────────────────────────────────────────────

function Show-ConnectPanel {
    param (
        [string]$IP,
        [string]$Model    = "Android Device",
        [string]$ConnType = "WiFi",   # "WiFi" or "USB"
        [string]$Mode     = "",
        [string]$Quality  = "",
        [string]$Latency  = "",
        [string]$Buffer   = "",
        [string]$Screen   = "OFF",
        [string]$Keyboard = "UHID Hardware Emulation"
    )
    Clear-Host
    Write-Host ""

    # Panel color & info based on actual connection type
    if ($ConnType -eq "USB") {
        $pc       = "Cyan"
        $modeLbl  = if ($Mode) { $Mode } else { "USB High-Performance Stream" }
        $qualLbl  = if ($Quality) { $Quality } else { "1920p / 16 Mbps / 60 fps" }
        $scrLbl   = "OFF  (saves battery)"
    } else {
        $pc       = "Green"
        $modeLbl  = if ($Mode) { $Mode } else { "Wireless Adaptive Stream" }
        $qualLbl  = if ($Quality) { $Quality } else { "1280p / 16 Mbps / 60 fps" }
        $scrLbl   = "OFF  (keeps WiFi chip active)"
    }

    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor $pc
    Write-PanelLine "              PHONEBOX  CONNECTION  CORE                " "White" $pc
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $pc
    Write-PanelLine "" "White" $pc
    Write-PanelLine "   Device  :  $Model" "White" $pc
    Write-PanelLine "   Target  :  $IP" "Yellow" $pc
    Write-PanelLine "   Connect :  $ConnType" $(if ($ConnType -eq "USB") {"Cyan"} else {"Green"}) $pc
    if ($Latency) {
        Write-PanelLine "   Latency :  $Latency" "DarkYellow" $pc
    }
    Write-PanelLine "" "White" $pc
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $pc
    Write-PanelLine "   Mode    :  $modeLbl" "Cyan" $pc
    Write-PanelLine "   Quality :  $qualLbl" "Cyan" $pc
    if ($Buffer) {
        Write-PanelLine "   Buffer  :  $Buffer" "Cyan" $pc
    }
    Write-PanelLine "   Screen  :  $scrLbl" "DarkCyan" $pc
    Write-PanelLine "   Keyboard:  $Keyboard" "DarkCyan" $pc
    Write-PanelLine "" "White" $pc
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor $pc
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  NEW: USB → Port 5555 Panel
#  Shown automatically when USB connected but port 5555 closed
# ──────────────────────────────────────────────────────────

function Show-UsbPortPanel {
    param ([string]$Serial, [string]$Model)
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-PanelLine "              USB → WIRELESS SETUP                      " "White" "Cyan"
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-PanelLine "" "White" "Cyan"
    Write-PanelLine "   Device  :  $Model" "White" "Cyan"
    Write-PanelLine "   Serial  :  $Serial" "DarkGray" "Cyan"
    Write-PanelLine "" "White" "Cyan"
    Write-PanelLine "   Port 5555 is NOT open on this device." "Yellow" "Cyan"
    Write-PanelLine "   Enable TCP/IP to allow wireless mirroring?" "Gray" "Cyan"
    Write-PanelLine "" "White" "Cyan"
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-PanelLine "   [Y] Enable TCP/IP 5555 (switch to WiFi after)" "Green" "Cyan"
    Write-PanelLine "   [N] Mirror now via USB  (no WiFi needed)" "Yellow" "Cyan"
    Write-PanelLine "   [B] Back to device list" "DarkGray" "Cyan"
    Write-PanelLine "" "White" "Cyan"
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  DISCONNECT MENU — now shows model name
# ──────────────────────────────────────────────────────────

function Show-DisconnectMenu {
    param ([string]$IP, [string]$Model = "Android Device", [string]$ConnType = "WiFi", [int]$Sel)
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "  ║" -NoNewline -ForegroundColor Red
    Write-Host "            CONNECTION  DROPPED / TERMINATED            " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Red
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "  ║" -NoNewline -ForegroundColor Red
    Write-Host "                                                          " -NoNewline
    Write-Host "║" -ForegroundColor Red

    foreach ($row in @(
        @{ T = "   Device  :  $Model";                       C = "Gray" },
        @{ T = "   IP/ID   :  $IP";                          C = "DarkGray" },
        @{ T = "   Type    :  $ConnType";                    C = "DarkGray" },
        @{ T = "   At      :  $((Get-Date).ToString('HH:mm:ss'))"; C = "DarkGray" }
    )) {
        Write-Host "  ║" -NoNewline -ForegroundColor Red
        Write-Host $row.T.PadRight($bw) -NoNewline -ForegroundColor $row.C
        Write-Host "║" -ForegroundColor Red
    }

    Write-Host "  ║" -NoNewline -ForegroundColor Red
    Write-Host "                                                          " -NoNewline
    Write-Host "║" -ForegroundColor Red
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "  ║" -NoNewline -ForegroundColor Red
    Write-Host "   What would you like to do?                             " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Red
    Write-Host "  ║" -NoNewline -ForegroundColor Red
    Write-Host "                                                          " -NoNewline
    Write-Host "║" -ForegroundColor Red

    $opts = @(
        "  ↺  Reconnect to $IP",
        "  ←  Back to Scanner",
        "  ✕  Exit PhoneBox"
    )
    for ($o = 0; $o -lt $opts.Count; $o++) {
        Write-Host "  ║" -NoNewline -ForegroundColor Red
        if ($Sel -eq $o) {
            Write-Host ("  ►" + $opts[$o]).PadRight($bw) -NoNewline -ForegroundColor Black -BackgroundColor Cyan
        } else {
            Write-Host ("    " + $opts[$o]).PadRight($bw) -NoNewline -ForegroundColor Gray
        }
        Write-Host "║" -ForegroundColor Red
    }

    Write-Host "  ║" -NoNewline -ForegroundColor Red
    Write-Host "                                                          " -NoNewline
    Write-Host "║" -ForegroundColor Red
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "    ↑↓  Navigate     ENTER  Confirm" -ForegroundColor DarkGray
}

# ══════════════════════════════════════════════════════════
#  MAIN LOOP
# ══════════════════════════════════════════════════════════

:MainMenu while ($true) {

    Show-ScanAnimation

    $ips = @()

    # ── 1. Enumerate ADB devices (USB & Network) ──
    Set-Location $scrcpyPath
    $adbDevs = & .\adb.exe devices
    foreach ($line in $adbDevs) {
        if ($line -match "^([a-zA-Z0-9_\-\.:]+)\s+device$") {
            $dev = $matches[1]

            # Get device model name
            $model = (& .\adb.exe -s $dev shell getprop ro.product.model 2>$null) -replace '[\r\n]', ''
            $model = $model.Trim()
            if (-not $model) { $model = "Android Device" }

            if ($dev -match "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})") {
                # ── Network ADB (already connected via WiFi) ──
                $ip = $matches[1]
                $ips += "$dev|$model|ADB_NET|$ip"

            } else {
                # ── USB ADB ── resolve WiFi IP + check port 5555
                $ip = ""

                # Try local wireless/tethering interfaces first (wlan0, wlan1, ap0, rndis0)
                foreach ($iface in @("wlan0", "wlan1", "ap0", "rndis0")) {
                    $out = (& .\adb.exe -s $dev shell ip addr show $iface 2>$null)
                    if ($out -match "inet\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})") {
                        $ip = $matches[1]
                        break
                    }
                }
                # Fallback to getprop (deprecated but works on older devices)
                if (-not $ip) {
                    foreach ($prop in @("dhcp.wlan0.ipaddress", "dhcp.wlan0.ip")) {
                        $out = (& .\adb.exe -s $dev shell getprop $prop 2>$null) -replace '[\r\n]', ''
                        if ($out.Trim()) { $ip = $out.Trim(); break }
                    }
                }
                # Last resort fallback to default route
                if (-not $ip) {
                    $out = (& .\adb.exe -s $dev shell ip route 2>$null)
                    if ($out -match "src\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})") {
                        $ip = $matches[1]
                    }
                }

                # BUG FIX: Check if port 5555 is already open on the device
                $port5555Open = $false
                if ($ip) {
                    $tcpCheck = [System.Net.Sockets.TcpClient]::new()
                    try {
                        $task = $tcpCheck.ConnectAsync($ip, 5555)
                        if ($task.Wait(400) -and $tcpCheck.Connected) { $port5555Open = $true }
                    } catch {}
                    finally { $tcpCheck.Close() }
                }

                if (-not $ip) { $ip = "No WiFi" }
                $portFlag = if ($port5555Open) { "5555_OPEN" } else { "5555_CLOSED" }

                $ips += "$dev|$model|ADB_USB|$ip|$portFlag"
            }
        }
    }

    # ── 2. ARP scan for WiFi devices with port 5555 open ──
    $arpOutput = arp -a | Select-String "dynamic"
    foreach ($line in $arpOutput) {
        if ($line -match "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})") {
            $checkIp = $matches[1]
            # Skip multicast / broadcast
            if ($checkIp -match "^(224\.|239\.|255\.)") { continue }

            # Skip IPs already represented in list
            $already = $false
            foreach ($ex in $ips) {
                $p = $ex -split "\|"
                if ($p[0] -match "^$([regex]::Escape($checkIp))" -or $p[3] -eq $checkIp) {
                    $already = $true; break
                }
            }
            if ($already) { continue }

            $tcpCheck = [System.Net.Sockets.TcpClient]::new()
            try {
                $task = $tcpCheck.ConnectAsync($checkIp, 5555)
                if ($task.Wait(200) -and $tcpCheck.Connected) {
                    $ips += "$checkIp||READY|$checkIp"
                }
                # Silently ignore if not reachable (no OTHER entries cluttering list)
            } catch {}
            finally { $tcpCheck.Close() }
        }
    }

    $ips = $ips | Select-Object -Unique
    # Sort: USB first → ADB_NET → READY → OTHER
    $ips = @($ips | Sort-Object {
        if ($_ -match "ADB_USB") { 0 }
        elseif ($_ -match "ADB_NET") { 1 }
        elseif ($_ -match "READY") { 2 }
        else { 3 }
    })

    $selectedIndex = 0
    $maxIndex = $ips.Count + 1

    # ── Selection loop ──
    while ($true) {
        Show-Menu -IPs $ips -SelectedIndex $selectedIndex
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode

        switch ($key) {
            38 { $selectedIndex--; if ($selectedIndex -lt 0) { $selectedIndex = $maxIndex } }
            40 { $selectedIndex++; if ($selectedIndex -gt $maxIndex) { $selectedIndex = 0 } }
            27 { Clear-Host; Write-Host ""; Write-Host "  PhoneBox terminated. Goodbye!" -ForegroundColor DarkGray; Write-Host ""; exit }
            13 { break }  # Enter → fall through
        }
        if ($key -eq 13) { break }
    }

    # ── Parse selection ──
    $targetSerial  = ""
    $targetIp      = ""
    $targetModel   = "Android Device"
    $isUsb         = $false
    $isAdbNet      = $false
    $port5555Open  = $false
    $connType      = "WiFi"

    if ($selectedIndex -eq $ips.Count) {
        # ── Manual IP entry ──
        Write-Host ""
        Write-Host "  ╭──────────────────────────────────────────────────────────╮" -ForegroundColor DarkGray
        Write-Host "  │" -NoNewline -ForegroundColor DarkGray
        Write-Host "   Enter the target device IP address:                    " -NoNewline -ForegroundColor White
        Write-Host "│" -ForegroundColor DarkGray
        Write-Host "  ╰──────────────────────────────────────────────────────────╯" -ForegroundColor DarkGray
        $inp = (Read-Host "  ► IP").Trim()
        if ([string]::IsNullOrWhiteSpace($inp)) { continue MainMenu }
        $targetIp     = $inp
        $targetSerial = $inp
        $connType     = "WiFi"

    } elseif ($selectedIndex -eq ($ips.Count + 1)) {
        # ── Rescan ──
        continue MainMenu

    } else {
        # ── Device from list ──
        $parts        = $ips[$selectedIndex] -split "\|"
        $targetSerial = $parts[0]
        $targetModel  = if ($parts[1] -and $parts[1].Trim()) { $parts[1].Trim() } else { "Android Device" }
        $statusCode   = if ($parts[2]) { $parts[2] } else { "OTHER" }
        $targetIp     = if ($parts.Count -gt 3 -and $parts[3] -ne "No WiFi" -and $parts[3]) { $parts[3] } else { "" }
        $portFlag     = if ($parts.Count -gt 4) { $parts[4] } else { "" }

        switch ($statusCode) {
            "ADB_USB"  { $isUsb = $true;  $port5555Open = ($portFlag -eq "5555_OPEN"); $connType = "USB" }
            "ADB_NET"  { $isAdbNet = $true; $connType = "WiFi" }
            "READY"    { $connType = "WiFi" }
            default    { $connType = "WiFi" }
        }
    }

    # ──────────────────────────────────────────────────────
    #  BUG FIX: USB device handling with port 5555 awareness
    # ──────────────────────────────────────────────────────

    if ($isUsb) {
        if (-not $port5555Open) {
            # Port 5555 is CLOSED → show prompt immediately
            :UsbChoice while ($true) {
                Show-UsbPortPanel -Serial $targetSerial -Model $targetModel
                $resp = (Read-Host "  ► Choice (Y / N / B)").Trim().ToUpper()

                if ($resp -eq 'Y') {
                    # Enable TCP/IP wirelessly
                    Set-Location $scrcpyPath
                    Write-Host ""
                    Write-Host "  ► Enabling TCP/IP on port 5555 for $targetModel..." -ForegroundColor Yellow
                    & .\adb.exe -s $targetSerial tcpip 5555
                    Start-Sleep -Seconds 3
                    Write-Host ""
                    Write-Host "  ✔ Done! Disconnect the USB cable, then rescan." -ForegroundColor Green
                    Write-Host "  Press any key to return to scanner..." -ForegroundColor DarkGray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    continue MainMenu

                } elseif ($resp -eq 'N') {
                    # Mirror via USB directly (no WiFi)
                    $connType = "USB"
                    $targetIp = $targetSerial   # use serial as scrcpy target
                    break UsbChoice

                } else {
                    continue MainMenu
                }
            }
        } else {
            # Port 5555 already open → connect wirelessly using WiFi IP
            $connType = "WiFi"
            if ([string]::IsNullOrWhiteSpace($targetIp)) {
                # Fallback: no WiFi IP but port is open — use serial via USB
                $connType = "USB"
                $targetIp = $targetSerial
            }
        }
    }

    # Final safety: if no IP, bail
    if ([string]::IsNullOrWhiteSpace($targetIp)) {
        Write-Host ""
        Write-Host "  [!] No valid IP or serial found. Press any key to rescan." -ForegroundColor DarkRed
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        continue MainMenu
    }

    # ──────────────────────────────────────────────────────
    #  CONNECT LOOP
    # ──────────────────────────────────────────────────────

    $maxRetries = 3
    $retryCount = 0
    :ConnectLoop while ($true) {
        Set-Location $scrcpyPath

        # Determine the scrcpy/adb target string & pre-calculate specs
        $modeLbl = ""
        $qualLbl = ""
        $latencyVal = ""
        $bufVal = ""

        if ($isUsb -and $connType -eq "USB") {
            $targetStr = $targetSerial
            $modeLbl = "USB High-Performance Stream"
            $qualLbl = "1920p / 16 Mbps / 60 fps"
            $latencyVal = "Wired (USB)"
            $bufVal = "None"
        } else {
            $targetStr = "$targetIp`:5555"

            # Show a simple scanning message on clean screen first
            Clear-Host
            Write-Host ""
            Write-Host "  ► Testing network latency to $targetIp..." -ForegroundColor DarkGray

            $ping = New-Object System.Net.NetworkInformation.Ping
            $pingTimes = @()
            for ($i = 0; $i -lt 3; $i++) {
                try {
                    $reply = $ping.Send($targetIp, 300) # 300ms timeout
                    if ($reply.Status -eq 'Success') {
                        $pingTimes += $reply.RoundtripTime
                    }
                } catch {}
            }

            # Calculate average roundtrip time
            $avgPing = 0
            $avgPingRound = 0
            if ($pingTimes.Count -gt 0) {
                $avgPing = ($pingTimes | Measure-Object -Average).Average
                $avgPingRound = [int][Math]::Round($avgPing)
            }

            # Adjust scrcpy parameters based on actual conditions
            if ($pingTimes.Count -eq 0) {
                # Connection might be blocked/ICMP disabled or extremely poor
                $maxSize = 1024
                $bitRate = "6M"
                $fps = 30
                $buffer = 150
                $latencyVal = "Unstable/No Response"
            } elseif ($avgPing -lt 15) {
                # Excellent connection (Close to router / 5GHz)
                $maxSize = 1280
                $bitRate = "12M"
                $fps = 60
                $buffer = 50
                $latencyVal = "Excellent (${avgPingRound}ms)"
            } elseif ($avgPing -lt 50) {
                # Good connection
                $maxSize = 1024
                $bitRate = "8M"
                $fps = 60
                $buffer = 100
                $latencyVal = "Good (${avgPingRound}ms)"
            } else {
                # High latency / unstable
                $maxSize = 800
                $bitRate = "4M"
                $fps = 30
                $buffer = 200
                $latencyVal = "High Latency (${avgPingRound}ms)"
            }
            $modeLbl = "Wireless Adaptive Stream"
            $qualLbl = "${maxSize}p / $bitRate / $fps fps"
            $bufVal = "${buffer}ms"
        }

        # Draw the clean panel with all computed data
        Show-ConnectPanel -IP $targetIp -Model $targetModel -ConnType $connType -Mode $modeLbl -Quality $qualLbl -Latency $latencyVal -Buffer $bufVal

        # ADB connection status checks (printed quietly underneath the panel)
        if ($connType -eq "WiFi") {
            # Check if already connected in ADB
            $adbDevices = & .\adb.exe devices
            $isDeviceConnected = $false
            foreach ($line in $adbDevices) {
                if ($line -match "^$([regex]::Escape($targetStr))\s+device$") {
                    $isDeviceConnected = $true
                    break
                }
            }

            if ($isDeviceConnected -and $retryCount -eq 0) {
                Write-Host "  [*] Status: Using existing ADB session." -ForegroundColor DarkGray
            } else {
                if ($retryCount -gt 0) {
                    Write-Host "  [*] Status: Reconnecting ADB (Attempt $retryCount of $maxRetries)..." -ForegroundColor DarkGray
                } else {
                    Write-Host "  [*] Status: Establishing ADB connection..." -ForegroundColor DarkGray
                }
                & .\adb.exe disconnect $targetStr | Out-Null
                & .\adb.exe connect $targetStr | Out-Null
                Start-Sleep -Seconds 1
            }
        } else {
            Write-Host "  [*] Status: Using USB session ($targetStr)..." -ForegroundColor DarkGray
        }

        Write-Host "  [*] Status: Launching scrcpy..." -ForegroundColor DarkGray

        # Build scrcpy arguments with quiet log level
        $scrcpyArgs = @("-s", $targetStr, "--stay-awake", "--keyboard=uhid", "--power-off-on-close", "--log-level=error")

        if ($connType -eq "WiFi") {
            $scrcpyArgs += @(
                "--turn-screen-off",
                "--max-size=$maxSize",
                "--video-bit-rate=$bitRate",
                "--max-fps=$fps",
                "--video-buffer=$buffer"
            )
        } else {
            # USB: high-performance, screen off
            $scrcpyArgs += @("--turn-screen-off", "--max-size=1920", "--video-bit-rate=16M", "--max-fps=60")
        }

        $sessionStart = Get-Date
        & .\scrcpy.exe $scrcpyArgs
        $scrcpyExitCode = $LASTEXITCODE
        $sessionDuration = ((Get-Date) - $sessionStart).TotalSeconds

        if ($scrcpyExitCode -ne 0) {
            # If scrcpy failed immediately, don't clear screen so we can see the error
            if ($sessionDuration -lt 3) {
                Write-Host ""
                Write-Host "  [!] scrcpy exited immediately (Exit Code: $scrcpyExitCode)." -ForegroundColor Red
                Write-Host "  Please check the error message above." -ForegroundColor Yellow
                Write-Host "  Press any key to show menu..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }

            # Connection dropped or failed to establish
            if ($sessionDuration -gt 10) {
                # It was working for a while, so reset retry count to give it a full 3 attempts
                $retryCount = 1
            } else {
                $retryCount++
            }

            if ($retryCount -le $maxRetries) {
                Write-Host ""
                Write-Host "  [!] Connection lost/failed (Exit Code: $scrcpyExitCode)." -ForegroundColor Red
                Write-Host "  ► Auto-retrying in 3 seconds (Attempt $retryCount of $maxRetries)..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
                continue ConnectLoop
            }
        }

        # Reset retryCount for future sessions on normal exit
        $retryCount = 0

        # ── Post-disconnect menu ──
        $dSel = 0
        while ($true) {
            Show-DisconnectMenu -IP $targetIp -Model $targetModel -ConnType $connType -Sel $dSel
            $dKey = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
            switch ($dKey) {
                38 { $dSel--; if ($dSel -lt 0) { $dSel = 2 } }
                40 { $dSel++; if ($dSel -gt 2) { $dSel = 0 } }
                13 { break }
            }
            if ($dKey -eq 13) { break }
        }

        switch ($dSel) {
            0 { continue ConnectLoop }
            1 { break ConnectLoop }
            2 {
                Clear-Host
                Write-Host ""
                Write-Host "  PhoneBox terminated. Goodbye!" -ForegroundColor DarkGray
                Write-Host ""
                exit
            }
        }
    }

} # :MainMenu
