#!/usr/bin/env bash
# Uninstall script to remove everything
# set -x # Uncomment to debug
trap 'rm -f ${TMPFILE}' EXIT
TMPFILE=$(mktemp)

source /etc/birdnet/birdnet.conf &> /dev/null
read -p "Be sure to run this script as the '${BIRDNET_USER}'"
crontab -l | sed -e '/birdnet/,+1d' > "${TMPFILE}"
crontab "${TMPFILE}"

sudo systemctl disable --now caddy
if [ -d /etc/systemd/system/caddy.service.d ];then
  sudo rm -drf /etc/systemd/system/caddy.service.d
fi
sudo rm -drf /etc/caddy
if [ -f /etc/systemd/system/"${SYSTEMD_MOUNT}" ];then
  sudo systemctl disable --now ${SYSTEMD_MOUNT}
  sudo rm /etc/systemd/system/"${SYSTEMD_MOUNT}"
fi

sudo systemctl disable --now birdnet_analysis.service
sudo rm /etc/systemd/system/birdnet_analysis.service

if [ -f /etc/systemd/system/birdnet_recording.service ];then
  sudo systemctl disable --now birdnet_recording.service
  sudo rm /etc/systemd/system/birdnet_recording.service
fi

if [ -f /etc/systemd/system/extraction.service ];then
  sudo systemctl disable --now extraction.service
  sudo rm /etc/systemd/system/extraction.service
fi

if [ -f /etc/systemd/system/livestream.service ];then
  sudo systemctl disable --now livestream.service
  sudo rm /etc/systemd/system/livestream.service
fi

sudo systemctl disable --now birdnet_log.service
sudo rm /etc/systemd/system/birdnet_log.service
sudo systemctl disable --now extraction_log.service
sudo rm /etc/systemd/system/extraction_log.service
sudo systemctl disable --now birdstats.service
sudo rm /etc/systemd/system/birdstats.service
sudo systemctl disable --now avahi-alias@birdnetsystem.local.service
sudo systemctl disable --now avahi-alias@birdlog.local.service
sudo systemctl disable --now avahi-alias@extractionlog.local.service
sudo systemctl disable --now avahi-alias@birdstats.local.service

if [ -f /etc/init.d/icecast2 ];then
  sudo /etc/init.d/icecast2 stop
  sudo systemctl disable --now icecast2
fi

sudo rm /etc/systemd/system/avahi-alias@.service
sudo rm /usr/local/bin/birdnet_analysis.sh
sudo rm /usr/local/bin/birdnet_stats.sh
sudo rm /usr/local/bin/birdnet_recording.sh
sudo rm /usr/local/bin/cleanup.sh
sudo rm /usr/local/bin/extract_new_birdsounds.sh
sudo rm /usr/local/bin/install_birdnet.sh
sudo rm /usr/local/bin/install_services.sh
sudo rm /usr/local/bin/reconfigure_birdnet.sh
sudo rm /usr/local/bin/species_notifier.sh
sudo rm /usr/local/bin/update_species.sh
sudo rm /usr/local/bin/uninstall.sh

sudo rm -drf /etc/birdnet
echo "Uninstall finished. Remove this directory with 'rm -drfv' to finish."
