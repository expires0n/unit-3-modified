#!/bin/bash
# Unit-3 timer display — waybar modülü her saniye çalıştırır
# State: /tmp/unit3-timer  (MODE=down/up, END/START epoch saniye)
STATE_FILE="/tmp/unit3-timer"
DONE_FLAG="/tmp/unit3-timer-done"
MAX_SEC=86400  # 24h sınır

fmt_down() {  # $1=kalan saniye → "12h 39m" ya da "MM:SS"
  local r=$1
  if [ "$r" -ge 3600 ]; then
    printf "%dh %02dm" $((r / 3600)) $(((r % 3600) / 60))
  else
    printf "%02d:%02d" $((r / 60)) $((r % 60))
  fi
}

fmt_up() {  # $1=geçen saniye → "HH:MM:SS" (24h'de sabitlenir)
  local e=$1
  [ "$e" -gt $MAX_SEC ] && e=$MAX_SEC
  printf "%02d:%02d:%02d" $((e / 3600)) $(((e % 3600) / 60)) $((e % 60))
}

[ ! -f "$STATE_FILE" ] && { echo "TMR --:--"; exit 0; }
# shellcheck disable=SC1090
source "$STATE_FILE" 2>/dev/null
NOW=$(date +%s)

if [ "$MODE" = "down" ] && [ -n "$END" ]; then
  REM=$((END - NOW))
  if [ "$REM" -le 0 ]; then
    if [ ! -f "$DONE_FLAG" ]; then
      notify-send "Timer" "Süre doldu!" 2>/dev/null
      touch "$DONE_FLAG"
    fi
    echo "TMR DONE"
    exit 0
  fi
  echo "TMR $(fmt_down "$REM")"
elif [ "$MODE" = "up" ] && [ -n "$START" ]; then
  echo "SW $(fmt_up $((NOW - START)))"
else
  echo "TMR --:--"
fi
