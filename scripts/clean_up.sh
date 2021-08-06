#!/usr/bin/env bash
source /etc/birdnet/birdnet.conf

FIND_DATE=*$(date --date="3 days ago" "+%F")*

cd "${PROCESSED}" || exit 1
FIND_DATE=*$(date --date="2 days ago" "+%F")*
find . -name "${FIND_DATE}" -exec rm -rfv {} +
