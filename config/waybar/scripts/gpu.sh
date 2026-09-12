#!/bin/bash
# AMD GPU kullanımı + sıcaklık — sysfs üzerinden, ek paket gerekmez
usage=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | sort -nr | head -1)
temp_raw=$(cat /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input 2>/dev/null | sort -nr | head -1)
if [ -z "$usage" ]; then
  echo '{"text":"GPU --","tooltip":"GPU bulunamadı"}'
  exit 0
fi
temp="--"
[ -n "$temp_raw" ] && temp="$((temp_raw / 1000))°C"
printf '{"text":"GPU %s%%","tooltip":"GPU %s%% / %s"}\n' "$usage" "$usage" "$temp"
