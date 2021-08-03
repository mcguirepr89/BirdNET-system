#!/usr/bin/env bash
source /etc/birdnet/birdnet.conf

REC_DATE=$(date --date="3 days ago" "+%F")
FIND_DATE=*$(date --date="3 days ago" "+%F")*

cd "${PROCESSED}" || exit 1
#echo
#echo "	Press enter to delete the following:"
#sleep 1
#find . -name "${FIND_DATE}"
#echo
#echo "	Ctrl+c to quit and keep those files
#    or Enter to remove them"
#read
#
find . -name "${FIND_DATE}" -exec rm -rfv {} +
