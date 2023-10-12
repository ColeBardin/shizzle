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
		if [ "$n" = "$cur" ] ; 
			then out+="%{F$neut}[$n]%{F$fg}"
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
	Mute="$(amixer -c 1 sget Master | grep "Mono: Playback" | awk '{print $6}')"
	Vol=$(amixer -c 1 sget Master | grep "Mono: Playback" | awk '{printf "%4s", substr($4, 2, length($4)-2)}')

	if [ $Mute = "[off]" ] ; then
		Vol="%{F$med}MUTE%{F$fg}"	
	fi

	echo "Vol: $Vol"

}

Battery() {
	Crg=$(acpi --battery | awk '{printf "%s", substr($3, 1, length($3)-1)}')
	Bat=$(acpi --battery | grep -oE "...%" | head -c-1)

	if [ "$Crg" = "Discharging" ] ; then
		Crg="__"
		CrgColor=$bad
	else
		Crg="~~"
		CrgColor=$good
	fi
	echo "Bat: $Bat%%{F$CrgColor}$Crg%{F$fg}"
}

Brightness() {
	Bright=$(brightnessctl g | awk '{printf "%3d", 100 * $1 / 255}')

	echo "Bright: $Bright%%"
}

Internet() {
	Con=$(nmcli dev status | grep -E "\b(wifi|ethernet)\b.*\bconnected\b")

	if [ -z "$Con" ] ; then
		Int="wifi"
		SSID="DISCONNECTED"
		Col=$bad
	else 
		Int=$(echo $Con | awk '{print $2}')
		SSID=$(echo $Con | awk '{print $4}')
		Col=$good

		if [ $Int = "ethernet" ] ; then
			Int="Eth"
			Col=$med
		fi
	fi

	echo "%{F$Col}$Int:%{F$fg} $SSID"
}

# Bar
while true; do
	bar="%{c} $(Clock) %{r} $(Internet)    $(CPU)    $(RAM)    $(Brightness)    $(Volume)    $(Battery)"
	out=""
	monitors=$(xrandr | grep -oE "^(DP|eDP|HDMI).* connected" | sed "s/ connected//")
	for m in $(echo "$monitors") ; do
		out="$out%{Sn"$m"}%{l} $(WS "$m") $bar"
	done
	echo "$out"
	sleep 0.1
done | lemonbar -g "x25++" -B "$bg" -F "$fg"
