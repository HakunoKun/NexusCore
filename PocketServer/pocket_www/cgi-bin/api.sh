#!/system/bin/sh
echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

# Gather system info
IP=$(getprop dhcp.rmnet0.ipaddress)
if [ -z "$IP" ]; then IP=$(getprop net.rmnet0.local-ip); fi
if [ -z "$IP" ]; then IP="Offline"; fi

OPERATOR=$(getprop gsm.operator.alpha)
if [ -z "$OPERATOR" ]; then OPERATOR="N/A"; fi

SIM_STATE=$(getprop gsm.sim.state)
if [ -z "$SIM_STATE" ]; then SIM_STATE="UNKNOWN"; fi

NETWORK_TYPE=$(getprop gsm.network.type)
if [ -z "$NETWORK_TYPE" ]; then NETWORK_TYPE="LTE"; fi

# RAM info (Pure shell)
while read -r name value unit; do
    if [ "$name" = "MemTotal:" ]; then MEM_TOT_KB=$value; fi
    if [ "$name" = "MemFree:" ]; then MEM_FRE_KB=$value; fi
done < /proc/meminfo

MEM_TOT_MB=$((MEM_TOT_KB / 1024))
MEM_FRE_MB=$((MEM_FRE_KB / 1024))

# Load avg (Pure shell)
read LOAD rest < /proc/loadavg

# Uptime (Pure shell)
read UPT_RAW rest < /proc/uptime
UPTIME=${UPT_RAW%%.*}

# Battery Level
BATT_CAP=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
BATT_VOLT=$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null)
if [ -z "$BATT_CAP" ]; then BATT_CAP="100"; fi
if [ -z "$BATT_VOLT" ]; then 
    BATT_VOLT="4200"
else
    BATT_VOLT=$((BATT_VOLT / 1000))
fi

# Connected WiFi Clients (Pure shell - reading from ARP)
CLIENTS_COUNT=0
while read -r ip hw flags mac mask dev; do
    if [ "$flags" = "0x2" ] && [ "$mac" != "00:00:00:00:00:00" ]; then
        CLIENTS_COUNT=$((CLIENTS_COUNT + 1))
    fi
done < /proc/net/arp

# Signal Strength
SIGNAL=$(getprop gsm.network.signal 2>/dev/null)
if [ -z "$SIGNAL" ]; then SIGNAL="Good"; fi

# Ping check for internet status & latency (Pure shell)
PING_MS="Offline"
# We ping 8.8.8.8 once with a 2-second timeout
PING_OUT=$(ping -c 1 -W 2 8.8.8.8 2>/dev/null)
if [ $? -eq 0 ]; then
    # Parse the 'time=XX.X' from the output
    # Example: 64 bytes from 8.8.8.8: seq=0 ttl=53 time=34.2 ms
    for word in $PING_OUT; do
        case "$word" in
            time=*)
                raw_time=${word#time=}
                # Round to integer for simplicity
                PING_MS="${raw_time%%.*} ms"
                ;;
        esac
    done
fi

# Bandwidth Usage (Cellular)
RX_BYTES=0
TX_BYTES=0
while read -r dev rx_bytes rest; do
    # Remove trailing colon from device name
    dev_name=${dev%:}
    if [ "$dev_name" = "rmnet0" ] || [ "$dev_name" = "rmnet_data0" ]; then
        RX_BYTES=$rx_bytes
        
        # We need to extract the 9th field (tx_bytes) from the rest of the string
        # rest contains: rx_packets errs drop fifo frame comp multi tx_bytes ...
        # Let's just use pure shell split
        set -- $rest
        TX_BYTES=$7
    fi
done < /proc/net/dev

RX_MB=$((RX_BYTES / 1048576))
TX_MB=$((TX_BYTES / 1048576))

# Generate JSON
echo "{"
echo "  \"ip\": \"$IP\","
echo "  \"operator\": \"$OPERATOR\","
echo "  \"sim_state\": \"$SIM_STATE\","
echo "  \"network_type\": \"$NETWORK_TYPE\","
echo "  \"signal\": \"$SIGNAL\","
echo "  \"ram_total\": \"$MEM_TOT_MB\","
echo "  \"ram_free\": \"$MEM_FRE_MB\","
echo "  \"load\": \"$LOAD\","
echo "  \"uptime\": \"$UPTIME\","
echo "  \"battery\": \"$BATT_CAP\","
echo "  \"voltage\": \"$BATT_VOLT\","
echo "  \"clients\": \"$CLIENTS_COUNT\","
echo "  \"rx_mb\": \"$RX_MB\","
echo "  \"tx_mb\": \"$TX_MB\","
echo "  \"ping\": \"$PING_MS\""
echo "}"
