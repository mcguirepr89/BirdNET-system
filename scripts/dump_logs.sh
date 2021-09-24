#!/usr/bin/env bash
# A comprehensive log dumper
# set -x # Uncomment to debug
source /etc/birdnet/birdnet.conf &> /dev/null
SERVICES=(avahi-alias@birdlog.local.service
avahi-alias@birdnetsystem.local.service
avahi-alias@birdstats.local.service
avahi-alias@extractionlog.local.service
avahi-alias@birdterminal.local.service
birdnet_analysis.service
birdnet_log.service
birdnet_recording.service
birdstats.service
birdterminal.service
caddy.service
extraction_log.service
extraction.service
extraction.timer
icecast2.service
livestream.service
${SYSTEMD_MOUNT})

# Create logs directory
[ -d ${HOME}/BirdNET-system/logs ] || mkdir ${HOME}/BirdNET-system/logs

# Create services logs
for i in "${SERVICES[@]}";do
  journalctl -u ${i} -n 100 --no-pager > ${HOME}/BirdNET-system/logs/${i}.log
  cp /etc/systemd/system/${i} ${HOME}/BirdNET-system/logs/${i}
done

# Create password-removed birdnet.conf
sed -e '/PWD=/d' ${HOME}/BirdNET-system/birdnet.conf > ${HOME}/BirdNET-system/logs/birdnet.conf 

# Get sound card specs
SOUND_CARD="$(aplay -L \
  | awk -F, '/^hw:/ {print $1}' \
  | grep -ve 'vc4' -e 'Head' -e 'PCH' \
  | uniq)"
echo "SOUND_CARD=${SOUND_CARD}" > ${HOME}/BirdNET-system/logs/soundcard
script -c "arecord -D ${SOUND_CARD} --dump-hw-params" -a ${HOME}/BirdNET-system/logs/soundcard

# TAR the logs into a ball
tar --remove-files -cvpzf ${HOME}/BirdNET-system/logs.tar.gz ${HOME}/BirdNET-system/logs
