#!/usr/bin/env bash
# A comprehensive log dumper
# set -x # Uncomment to debug
source /etc/birdnet/birdnet.conf &> /dev/null
LOG_DIR="${HOME}/BirdNET-system/logs"
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
[ -d ${LOG_DIR} ] || mkdir ${LOG_DIR}

# Create services logs
for i in "${SERVICES[@]}";do
  journalctl -u ${i} -n 100 --no-pager > ${LOG_DIR}/${i}.log
  cp /etc/systemd/system/${i} ${LOG_DIR}/${i}
done

# Create password-removed birdnet.conf
sed -e '/PWD=/d' ${HOME}/BirdNET-system/birdnet.conf > ${LOG_DIR}/birdnet.conf 

# Create password-removed Caddyfile
if [ -f /etc/caddy/Caddyfile ];then
  sed -e '/basicauth/,+2d' /etc/caddy/Caddyfile > ${LOG_DIR}/birdnet.conf 
fi  

# Get sound card specs
SOUND_CARD="$(aplay -L \
  | awk -F, '/^hw:/ {print $1}' \
  | grep -ve 'vc4' -e 'Head' -e 'PCH' \
  | uniq)"
echo "SOUND_CARD=${SOUND_CARD}" > ${LOG_DIR}/soundcard
script -c "arecord -D ${SOUND_CARD} --dump-hw-params" -a ${LOG_DIR}/soundcard

# Get system info
CALLS=("df -h" "free -h" "ifconfig" "find ${RECS_DIR}")

for i in ${CALLS[@]};do
  ${i} >> ${LOG_DIR}/sysinfo
done

# TAR the logs into a ball
tar --remove-files -cvpzf ${HOME}/BirdNET-system/logs.tar.gz ${LOG_DIR}
