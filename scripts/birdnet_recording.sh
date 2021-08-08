#!/usr/bin/env bash
source /etc/birdnet/birdnet.conf

if [ -z ${REC_CARD} ];then
  REC_CARD=$(  aplay -L | grep -e '^hw:CARD' | cut -d',' -f1 | tail -n1)
fi

if pgrep arecord &> /dev/null ;then
  echo "Recording"
else
  arecord -f dat -t wav --max-file-time 60 -D "${REC_CARD}"\
    --use-strftime ${RECS_DIR}/%B-%Y/%d-%A/%F-birdnet-%I:%M%P.wav
fi
