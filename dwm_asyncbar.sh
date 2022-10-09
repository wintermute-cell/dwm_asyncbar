#!/bin/bash

# obtainer functions
nettraf(){
    # taken from:
    # github.com/LukeSmithxyz/voidrice/blob/master/.local/bin/statusbar/sb-nettraf
    update() {
        sum=0
        for arg; do
            read -r i < "$arg"
            sum=$(( sum + i ))
        done
        cache=/tmp/${1##*/}
        [ -f "$cache" ] && read -r old < "$cache" || old=0
        printf %d\\n "$sum" > "$cache"
        printf %d\\n $(( sum - old ))
    }

    rx=$(update /sys/class/net/[ew]*/statistics/rx_bytes)
    tx=$(update /sys/class/net/[ew]*/statistics/tx_bytes)

    printf "↓%4sB ↑%4sB\\n" $(numfmt --to=iec $rx $tx)
}

battery(){
    battery=$(cat /sys/class/power_supply/BAT1/capacity)
    charge_status=$(cat /sys/class/power_supply/BAT1/status)
    charge_symbol="?"
    if [ "$charge_status" = "Discharging" ]; then
        charge_symbol=""
    else
        charge_symbol=""
    fi
    echo -e "$charge_symbol $battery%"
}

dte(){
    dte=$(date "+%d/%m/%y | %H:%M")
    echo -e "$dte"
}

mkfifo /tmp/dwmbar_shortpipe
mkfifo /tmp/dwmbar_longpipe

# loops
if [[ $(cat /etc/hostname) == "winterdesk" ]]; then
    while true; do # one second loop
        echo $(nettraf) > /tmp/dwmbar_shortpipe
        sleep 1s
    done &
    while true; do # 20s loop
        echo $(dte) > /tmp/dwmbar_longpipe
        sleep 20s
    done &
    while true; do
        SHORT=""
        LONG=""

        read -t 0.1 -r holder<>/tmp/dwmbar_shortpipe && sline="$holder"
        SHORT="$sline"
        read -t 0.1 -r holder<>/tmp/dwmbar_longpipe && lline="$holder"
        LONG="$lline"

        xsetroot -name "$SHORT || $LONG ||"
        sleep 0.8s
    done
else
    # device specific values
    BATTERY=$(battery)
    while true; do
        xsetroot -name "$(battery) || $(dte) ||"
        sleep 0.2m
    done &
fi
