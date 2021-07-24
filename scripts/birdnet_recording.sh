#!/usr/bin/env bash
# set -x
source /etc/birdnet/birdnet.conf

trap 'rm -f "$tmpfile"' EXIT
# Location is US ZIP
tmpfile=$(mktemp)

if [ -z ${REC_CARD} ];then
  REC_CARD=$(  aplay -L | grep -e '^hw:CARD' | cut -d',' -f1 | tail -n1)
fi

# Obtain sunrise and sunset raw data from weather.com
wget -q "https://weather.com/weather/today/l/$ZIP" -O "$tmpfile"

SUNR=$(grep SunriseSunset "$tmpfile" \
  | grep -oE '((1[0-2]|0?[1-9]):([0-5][0-9]) ?([AaPp][Mm]))' | head -1)
SUNS=$(grep SunriseSunset "$tmpfile" \
  | grep -oE '((1[0-2]|0?[1-9]):([0-5][0-9]) ?([AaPp][Mm]))' | tail -1)


sunrise_start=$(date --date="$SUNR" +%k)
sunrise_end=$((sunrise_start + 2 ))
sunset_end=$(date --date="$SUNS" +%k)
sunset_start=$((sunset_end - 2))

XDG_RUNTIME_DIR=/run/user/1000
HOUR=$(date +%k)

if [ "$HOUR" -ge "${sunrise_start}" ] \
  && [ "$HOUR" -le "${sunrise_end}" ] \
  && ! pgrep arecord \
  || [ "$HOUR" -ge "${sunset_start}" ] \
  && [ "$HOUR" -le "${sunset_end}" ] \
  && ! pgrep arecord;then
  echo "Starting Recording!"
  arecord -f dat -t wav --max-file-time 60 -D "${REC_CARD}"\
    --use-strftime ${DIR_TO_USE}/%B-%Y/%d-%A/%F-birdnet-%I:%M%P.wav
elif [ "$HOUR" -ge "${sunrise_start}" ] \
  && [ "$HOUR" -le "${sunrise_end}" ] \
  && pgrep arecord \
  || [ "$HOUR" -ge "${sunset_start}" ] \
  && [ "$HOUR" -le "${sunset_end}" ] \
  && pgrep arecord;then
  echo "Currently recording"
else
  echo "Making sure recording is not happening"
  pkill arecord
fi
