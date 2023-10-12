#!/bin/sh

WS() {
	ws=$(i3-msg -t get_workspaces)
	nums=$(echo $ws | jq -r '.[].name' | sort -n)
	cur=$(echo $ws | jq -r --arg mon "$1" '.[] | select(.visible == true and .output == $mon) | .name')

	out=""
	for n in $(echo "$nums") ; do
		if [ "$n" = "$cur" ] ; then
			out+="[$n]"
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
	Vol=$(amixer sget Master | grep "Front Left:" | awk '{printf "%4s", substr($5, 2, length($5)-2)}')

	echo "Vol: $Vol"
}

# Bar
while true; do
	bar="%{c} $(Clock) %{r} $(CPU)    $(RAM)    $(GPU)    $(Volume) "
	out=""
	monitors=$(xrandr | grep -oE "^(DP|eDP|HDMI).* connected" | sed "s/ connected//")
	for m in $(echo "$monitors") ; do
		out="$out%{Sn"$m"}%{l} $(WS "$m") $bar"
	done
	echo "$out"
	sleep 0.2
done | lemonbar -g "x25++" -B "#102114" -F "#dbdbdb"
