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
sudo rm -drf /etc/caddy
if [ ! -z "${SYSTEMD_MOUNT}" ];then
  sudo systemctl disable --now ${SYSTEMD_MOUNT}
fi
sudo rm /etc/systemd/system/birdnet_analysis.service
if [ -f /etc/systemd/system/extraction.service];then
  sudo rm /etc/systemd/system/extraction.service
fi
if [ -f /etc/systemd/system/${SYSTEMD_MOUNT}];then
  sudo rm /etc/systemd/system/${SYSTEMD_MOUNT}
fi
sudo rm /usr/local/bin/birdnet_analysis.sh
sudo rm /usr/local/bin/birdnet_recording.sh
sudo rm /usr/local/bin/clean_up.sh
sudo rm /usr/local/bin/extract_new_birdsounds.sh
sudo rm /usr/local/bin/install_birdnet.sh
sudo rm /usr/local/bin/install_systemd.sh
sudo rm /usr/local/bin/reconfigure_birdnet.sh
sudo rm /usr/local/bin/species_notifier.sh
sudo rm /usr/local/bin/update_species.sh
sudo rm /usr/local/bin/uninstall.sh

sudo rm -drf /etc/birdnet
echo "Uninstall finished. Remove this directory with 'rm -drfv' to finish."
