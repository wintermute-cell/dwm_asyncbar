#!/bin/bash

# DEFINITIONS
SEP="||"

# ----------------
# MODULE FUNCTIONS
# ----------------
nettraf(){ # displays up- and download traffic
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

    printf "↓%4sB ↑%4sB\\n $SEP" $(numfmt --to=iec $rx $tx)
}

battery(){ # displays battery % and charging state if a battery is present
    batpath="/sys/class/power_supply/"
    if [ -d ${batpath}BAT0 ] || [ -d ${batpath}BAT1 ]; then
        # prefer showing external BAT1 over internal BAT0
        if [ -f ${batpath}BAT1/capacity ]; then
            battery=$(cat ${batpath}BAT1/capacity)
            charge_status=$(cat ${batpath}BAT1/status)
        elif [ -f ${batpath}BAT0/capacity ]; then
            battery=$(cat ${batpath}BAT0/capacity)
            charge_status=$(cat ${batpath}BAT0/status)
        fi
        charge_symbol="?"
        if [ "$charge_status" = "Discharging" ]; then
            charge_symbol=""
        else
            charge_symbol=""
        fi
        echo -e "$charge_symbol $battery% $SEP"
    else
        echo -e "" # return empty str if there is no BAT1
    fi
}

dte(){ # displays date and time
    dte=$(date "+%d/%m/%y | %H:%M")
    echo -e "$dte $SEP"
}




# pipes for communication between the differently timed loops
mkfifo /tmp/dwmbar_shortpipe
mkfifo /tmp/dwmbar_longpipe

# ----------------
#      LOOPS
# ----------------

# getter loops
while true; do # one second loop
    echo $(nettraf) > /tmp/dwmbar_shortpipe
    sleep 1s
done &
while true; do # 20s loop
    echo "$(dte) $(battery)" > /tmp/dwmbar_longpipe
    sleep 20s
done &

# main loop
while true; do # calls xsetroot using the data from the pipes
    SHORT=""
    LONG=""

    read -t 0.1 -r holder<>/tmp/dwmbar_shortpipe && sline="$holder"
    SHORT="$sline"
    read -t 0.1 -r holder<>/tmp/dwmbar_longpipe && lline="$holder"
    LONG="$lline"

    xsetroot -name "$SHORT $LONG"
    sleep 0.8s
done
