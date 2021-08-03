#!/usr/bin/env bash
source /etc/birdnet/birdnet.conf

<<<<<<< HEAD
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
=======
FIND_DATE=*$(date --date="2 days ago" "+%F")*

cd "${PROCESSED}" || exit 1

>>>>>>> 9e676fe5bf0f91d29d8fe31aec4c56cfdd938e72
find . -name "${FIND_DATE}" -exec rm -rfv {} +
