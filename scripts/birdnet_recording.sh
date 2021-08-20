#!/usr/bin/env bash
source /etc/birdnet/birdnet.conf

if pgrep arecord &> /dev/null ;then
  echo "Recording"
else
  if [ -z ${REC_CARD} ];then
    arecord -f dat -t wav --max-file-time 60 \
      --use-strftime ${RECS_DIR}/%B-%Y/%d-%A/%F-birdnet-%I:%M%P.wav
  else
    arecord -f dat -t wav --max-file-time 60 -D "${REC_CARD}"\
      --use-strftime ${RECS_DIR}/%B-%Y/%d-%A/%F-birdnet-%I:%M%P.wav
  fi
fi
