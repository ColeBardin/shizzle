#!/bin/sh

bgc="#102114"
fgc="#dbdbdb"
bad="#ff0000"
med="#ffcd05"
good="#00ff08"
neut="#0390fc"

gap="  "

desktop="cputer"
laptop="coltop2"

WS() {
    ws=$(i3-msg -t get_workspaces)
    nums=$(echo $ws | jq -r '.[].name' | sort -n)
    cur=$(echo $ws | jq -r --arg mon "$1" '.[] | select(.visible == true and .output == $mon) | .name')

    out=""
    for n in $(echo "$nums") ; do
        if [ "$n" = "$cur" ] ; then
            out+="%{F$neut}[$n]%{F$fgc}"
        else
            out+=" $n "
        fi
    done
    echo "$1: $out"
}

Clock() {
    DATETIME=$(date "+%a %b %d, %H:%M")

    echo "$DATETIME"
}

CPU() {
    CpuLoad=$(top -n 1 | grep "Cpu(s)" | awk '{printf "%5.1f", $2}')
    CpuTemp=$(sensors | grep "Tctl" | awk '{printf "%6s", substr($2, 2, length($2)-1)}')

    echo "$gap CPU: $CpuLoad%% / $CpuTemp"
}

RAM() {
    RamLoad=$(free | grep Mem: | awk '{printf "%5.1f", (100 * $3 / $2)}')
    RamUsed=$(free -m | grep Mem: | awk '{printf "%5.2fGB", ($3 / 1024)}')

    echo "$gap RAM: $RamLoad%% / $RamUsed"
}

GPU() {
    if [ "$HOSTNAME" = "$laptop" ]; then
        GpuTemp=$(sensors | grep edge | awk '{printf "%3.1f°C", substr($2, 2, length($2))}')
        GpuLoad=$(cat /sys/class/drm/card1/device/gpu_busy_percent | awk '{printf "%5.1f", $1}')
    else
        GpuTemp=$(nvidia-smi -a | grep "GPU Current Temp" | awk '{printf "%4.1f°C", $5}')
        GpuLoad=$(nvidia-smi -a | grep "Gpu" | awk '{printf "%5.1f", $3}')
    fi
    
    echo "$gap GPU: $GpuLoad%% / $GpuTemp"
}

Volume() {
    Mute=$(pactl get-sink-mute @DEFAULT_SINK@)
    Vol=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{printf "%3d", $5}')%

    if [ "$Mute" = "Mute: yes" ] ; then
        Vol="%{F$med}MUTE%{F$fgc}"
        /usr/bin/xbacklight -ctrl platform::mute 100
    else
        /usr/bin/xbacklight -ctrl platform::mute 0
    fi

    echo "$gap Vol: $Vol"
}

Battery() {
    if [ "$HOSTNAME" = "$laptop" ]; then
        Crg=$(acpi --battery | awk '{printf "%s", substr($3, 1, length($3)-1)}')

        if [ "$Crg" = "Discharging" ] ; then
            Bat=$(acpi --battery | awk '{printf "%3d", substr($4, 1, length($4)-2)}')
            Crg="__"
            CrgColor=$bad
        elif [ "$Crg" = "Charging" ]; then
            Bat=$(acpi --battery | awk '{printf "%3d", substr($4, 1, length($4)-2)}')
            Crg="~~"
            CrgColor=$good
        elif [ "$Crg" = "No" ]; then
            Bat=$(acpi --battery | awk '{printf "%3d", substr($5, 1, length($5)-1)}')
            Crg="||"
            CrgColor=$med
        else
            Bat=$(acpi --battery | awk '{printf "%3d", substr($4, 1, length($4)-1)}')
            Crg="||"
            CrgColor=$med
        fi
        echo "$gap Bat: $Bat%%%{F$CrgColor}$Crg%{F$fgc}"
    fi
}

Brightness() {
    if [ "$HOSTNAME" = "$laptop" ]; then
        Bright=$(xbacklight -get | awk '{printf "%3d", $1}')
    else
        Bright=$(/usr/local/bin/bright | awk '{printf "%3d", $1}')
    fi

    echo "$gap Bright: $Bright%%"
}

Network() {
    Con=$(nmcli dev status | grep -E "\b(wifi|ethernet)\b.*\bconnected\b")

    if [ -z "$Con" ] ; then
        Int="wifi"
        SSID="NONE"
        Col=$bad
        VPN=""
    else
        Int=$(echo $Con | awk '{print $2}')
        if [ $Int = "ethernet" ] ; then
            Int="Eth"
            SSID="Wired"
            Col=$med
        else
            SSID=$(nmcli dev wifi show | grep -i "SSID" | awk '{for(i=2;i<=NF;++i) printf "%s%s", $i, i==NF?"":" "}')
            Col=$good
        fi

        if [ ! -z "$(nordvpn status | grep  "Status: Connected")" ]; then
            VPN="(%{F$neut}VPN%{F$fgc})"
        else
            VPN="(%{F$bad}VPN%{F$fgc})"
        fi
    fi

    echo "$gap %{F$Col}$Int:%{F$fgc} $SSID$VPN"
}

# Bar
while true; do
    bar="%{c} $(Clock) %{r}$(Network)$(CPU)$(RAM)$(GPU)$(Brightness)$(Volume)$(Battery) "
    out=""
    monitors=$(xrandr | grep -oE "^(DP|eDP|HDMI).* connected" | sed "s/ connected//")
    for m in $(echo "$monitors") ; do
        out="$out%{Sn"$m"}%{l} $(WS "$m") $bar"
    done
    echo "$out"
    sleep 0.5
done | lemonbar -g "x25++" -B "$bgc" -F "$fgc"

