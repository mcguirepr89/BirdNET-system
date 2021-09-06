#!/usr/bin/env bash
# Install services and dependencies based on birdnet.conf
my_dir=$(realpath $(dirname $0))
HOME=$(sudo -u ${BIRDNET_USER} echo $HOME)
USER=$(sudo -u ${BIRDNET_USER} echo $USER)
source $(dirname ${my_dir})/birdnet.conf

install_recording_service() {
  echo "Checking for alsa-utils"
  if which arecord &> /dev/null ;then
    echo "ALSA-Utils installed"
  else
    echo "Installing alsa-utils"
    apt -qqq update &> /dev/null
    apt install -y alsa-utils &> /dev/null
  fi

  echo "Installing birdnet_recording.service"
  cat << EOF > /etc/systemd/system/birdnet_recording.service
[Unit]
Description=BirdNET Recording
[Service]
Environment=XDG_RUNTIME_DIR=/run/user/1000
Restart=always
Type=simple
RestartSec=3
User=${BIRDNET_USER}
ExecStart=/usr/local/bin/birdnet_recording.sh
[Install]
WantedBy=multi-user.target
EOF
echo "Enabling birdnet_recording.service"
systemctl enable birdnet_recording.service
# Ensure these variables remain empty since they must remain
# empty while the birdnet_recording.service is enabled.
REMOTE_HOST=
REMOTE_RECS_DIR=
REMOTE_USER=
}

install_systemd_mount() {
  echo "Checking for SSHFS to mount remote filesystem"
  if ! which sshfs &> /dev/null ;then
    echo "Installing SSHFS"
    apt update &> /dev/null
    apt install -y sshfs &> /dev/null
  fi
  echo "Adding remote host key to ${HOME}/.ssh/known_hosts"
  sudo -u ${BIRDNET_USER} \
    ssh-keyscan -H ${REMOTE_HOST} >> ${HOME}/.ssh/known_hosts
  if [ ! -f ${HOME}/.ssh/id_ed25519.pub ];then
    sudo -u ${BIRDNET_USER} ssh-keygen -t ed25519 \
      -f ${HOME}/.ssh/id_ed25519 -P ""
  fi
  chown -R ${BIRDNET_USER}:${BIRDNET_USER} ${HOME}/.ssh/ &> /dev/null
  echo "Copying public key to ${REMOTE_HOST}"
  ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST}
  echo "Be sure to set that up before running birdnet_analysis"
}

install_extraction_service() {
  echo "Installing the extraction.service"
  cat << EOF > /etc/systemd/system/extraction.service
[Unit]
Description=BirdNET BirdSound Extraction
[Service]
Restart=on-failure
RestartSec=3
Type=simple
User=${BIRDNET_USER}
ExecStart=/usr/local/bin/extract_new_birdsounds.sh
[Install]
WantedBy=multi-user.target
EOF
  cat << EOF > /etc/systemd/system/extraction.timer
[Unit]
Description=BirdNET BirdSound Extraction Timer
Requires=extraction.service
[Timer]
Unit=extraction.service
OnCalendar=*:0/10
[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now extraction.timer
  systemctl enable extraction.service
  echo "Adding the species_updater.cron"
  if ! crontab -u ${BIRDNET_USER} -l &> /dev/null;then
    crontab -u ${BIRDNET_USER} \
      $(dirname ${my_dir})/templates/species_updater.cron &> /dev/null
  else
    crontab -u ${BIRDNET_USER} -l > ${TMPFILE}
    cat $(dirname ${my_dir})/templates/species_updater.cron >> ${TMPFILE}
    crontab -u ${BIRDNET_USER} "${TMPFILE}" &> /dev/null
  fi
}
