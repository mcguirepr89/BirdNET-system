#!/usr/bin/env bash
# Reconfigure the BirdNET-system
source /etc/birdnet/birdnet.conf
uninstall.sh
${HOME}/BirdNET-system/scripts/new_install_config.sh
sudo ${HOME}/BirdNET-system/scripts/new_install_services.sh
echo "BirdNET-system has now been reconfigured."
