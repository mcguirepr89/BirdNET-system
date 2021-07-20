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
sudo rm -v -drf /etc/caddy
if [ ! -z "${SYSTEMD_MOUNT}" ];then
  sudo systemctl disable --now ${SYSTEMD_MOUNT}
fi
sudo rm -v /etc/systemd/system/birdnet_analysis.service
sudo rm -v /etc/systemd/system/extraction.service
sudo rm -v /etc/systemd/system/${SYSTEMD_MOUNT}

sudo rm -v /usr/local/bin/birdnet_analysis.sh
sudo rm -v /usr/local/bin/birdnet_recording.sh
sudo rm -v /usr/local/bin/extract_new_birdsounds.sh
sudo rm -v /usr/local/bin/install_birdnet.sh
sudo rm -v /usr/local/bin/install_systemd.sh
sudo rm -v /usr/local/bin/reconfigure_birdnet.sh
sudo rm -v /usr/local/bin/species_notifier.sh
sudo rm -v /usr/local/bin/update_species.sh
sudo rm -v /usr/local/bin/uninstall.sh

sudo rm -v -drf /etc/birdnet
echo "Uninstall finished. Remove this directory with 'rm -drfv' to finish."
