#!/bin/sh

bg="#102114"
fg="#dbdbdb"
bad="#ff0000"
med="#ffcd05"
good="#00ff08"
neut="#0390fc"

WS() {
	ws=$(i3-msg -t get_workspaces)
	nums=$(echo $ws | jq -r '.[].name' | sort -n)
	cur=$(echo $ws | jq -r --arg mon "$1" '.[] | select(.visible == true and .output == $mon) | .name')

	out=""
	for n in $(echo "$nums") ; do
		if [ "$n" = "$cur" ] ; then
			out+="%{F$neut}[$n]%{F$fg}"
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
	CpuTemp=$(sensors | grep Tctl | awk '{printf "%6s", substr($2, 2, length($2)-1)}')
	CpuLoad=$(top -n1 | grep %Cpu | awk '{printf "%5.1f", $2}')

	echo "CPU: $CpuLoad%% / $CpuTemp"
}

RAM() {
	RamLoad=$(free | grep Mem: | awk '{printf "%5.1f", (100 * $3 / $2)}')
	RamUsed=$(free -m | grep Mem: | awk '{printf "%5.2fGB", ($3 / 1024)}')

	echo "RAM: $RamLoad%% / $RamUsed"
}

GPU() {
	GpuTemp=$(nvidia-smi -a | grep "GPU Current Temp" | awk '{printf "%4.1f°C", $5}')
	GpuLoad=$(nvidia-smi -a | grep "Gpu" | awk '{printf "%5.1f", $3}')
	
	echo "GPU: $GpuLoad%% / $GpuTemp"
}

Volume() {
    Mute=$(pactl get-sink-mute @DEFAULT_SINK@)
    Vol=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print $5}')

	if [ "$Mute" = "Mute: no" ] ; then
		Vol="%{F$med}MUTE%{F$fg}"
	fi

	echo "Vol: $Vol"
}

Network() {
	Con=$(nmcli dev status | grep -E "\b(wifi|ethernet)\b.*\bconnected\b")

	if [ -z "$Con" ] ; then
		Int="wifi"
		SSID="DISCONNECTED"
		Col=$bad
        VPN=""
	else
		Int=$(echo $Con | awk '{print $2}')
		SSID=$(echo $Con | awk '{print $4}')
		Col=$good

		if [ $Int = "ethernet" ] ; then
			Int="Eth"
			Col=$med
		fi

        if [ ! -z "$(nordvpn status | grep  "Status: Connected")" ]; then
            VPN=" (%{F$neut}VPN%{F$fg})"
        else
            VPN=" (%{F$bad}VPN%{F$fg})"
        fi
	fi

	echo "%{F$Col}$Int:%{F$fg} $SSID$VPN"
}

# Bar
while true; do
	bar="%{c} $(Clock) %{r} $(Network)    $(CPU)    $(RAM)    $(GPU)    $(Volume) "
	out=""
	monitors=$(xrandr | grep -oE "^(DP|eDP|HDMI).* connected" | sed "s/ connected//")
	for m in $(echo "$monitors") ; do
		out="$out%{Sn"$m"}%{l} $(WS "$m") $bar"
	done
	echo "$out"
	sleep 0.2
done | lemonbar -g "x25++" -B "$bg" -F "$fb"
