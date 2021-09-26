#!/usr/bin/env bash
# Live Audio Stream Service Script
source /etc/birdnet/birdnet.conf
trap 'rm -f ${SOUND_PARAMS}' EXIT SIGHUP SIGINT
SOUND_PARAMS=$(mktemp)
SOUND_CARD="$(aplay -L \
  | awk -F, '/^hw:/ {print $1}' \
  | grep -ve 'vc4' -e 'Head' -e 'PCH' \
  | uniq)"
script -c "arecord -D ${SOUND_CARD} --dump-hw-params" -a "${SOUND_PARAMS}" &> /dev/null

CHANNELS=$(awk '/CHANN/ { print $2 }' "${SOUND_PARAMS}"| sed 's/\r$//')

if [ -z ${REC_CARD} ];then
  echo "Stream not supported"
else
  ffmpeg -loglevel 52 -ac ${CHANNELS} -f alsa -i ${REC_CARD} -acodec libmp3lame \
    -b:a 320k -ac ${CHANNELS} -content_type 'audio/mpeg' \
    -f mp3 icecast://source:${ICE_PWD}@localhost:8000/stream -re
fi
