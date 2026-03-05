#!/bin/bash
# Swaybar status script

while true; do
    # Volume - get default sink volume
    default_sink=$(pactl info | grep "Default Sink:" | cut -d: -f2 | xargs)
    if [ -n "$default_sink" ]; then
        vol_info=$(pactl list sinks | grep -A 10 "Name: $default_sink" | grep "Volume:")
        vol=$(echo "$vol_info" | head -1 | awk '{print $5}' | tr -d '%')
        mute=$(pactl list sinks | grep -A 10 "Name: $default_sink" | grep "Mute:" | awk '{print $2}')
    else
        # Fallback to first sink
        vol=$(pactl list sinks | grep -m1 'Volume:' | awk '{print $5}' | tr -d '%')
        mute=$(pactl list sinks | grep -m1 'Mute:' | awk '{print $2}')
    fi
    
    if [ "$mute" = "yes" ]; then
        vol_str="MUTED"
    else
        vol_str="${vol}%"
    fi
    
    # Battery
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        bat=$(cat /sys/class/power_supply/BAT0/capacity)
        bat_status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")
        if [ "$bat_status" = "Charging" ]; then
            bat_str="${bat}%+"
        else
            bat_str="${bat}%"
        fi
    else
        bat_str="AC"
    fi
    
    # Network - improved detection
    if command -v nmcli >/dev/null 2>&1; then
        # Check WiFi connection
        wifi=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | grep '^yes')
        if [ -n "$wifi" ]; then
            ssid=$(echo "$wifi" | cut -d: -f2)
            signal=$(echo "$wifi" | cut -d: -f3)
            net_str="${ssid}"
        else
            # Check Ethernet connection
            eth=$(nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep 'ethernet' | grep 'connected' | cut -d: -f1)
            if [ -n "$eth" ]; then
                net_str="${eth}"
            else
                # Check if any device is connected
                connected=$(nmcli -t -f STATE g 2>/dev/null | head -1)
                if [ "$connected" = "connected" ]; then
                    net_str="connected"
                else
                    net_str="disconnected"
                fi
            fi
        fi
    else
        net_str="N/A"
    fi
    
    # Date/Time in 12-hour format (no seconds)
    date_str=$(date +'%Y-%m-%d %I:%M %p')
    
    echo "VOL:${vol_str} | BAT:${bat_str} | NET:${net_str} | ${date_str}"
    sleep 1
done
