#!/usr/bin/env bash
# Update the species list
# set -x
trap 'rm -f "$TMPFILE"' SIGINT SIGTERM EXIT

source /etc/birdnet/birdnet.conf

TMPFILE=$(mktemp) || exit 1

[ -f ${IDFILE} ] || touch ${IDFILE}

IDFILEBAKUP="${IDFILE}.bak"

if [ $(find ${ANALYZED} -name '*txt' | wc -l) -ge 1 ];then
  sort $(find ${ANALYZED} -name '*txt') \
    | awk '/Spectro/ {print $11" "$12}' \
    | sort -u > "$TMPFILE"
  cat "$IDFILE" >> "$TMPFILE"
  cp "$IDFILE" "$IDFILEBAKUP"
  sort -u "$TMPFILE" > "$IDFILE"
  cat "$IDFILE"
else
  cat "$IDFILE"
fi
