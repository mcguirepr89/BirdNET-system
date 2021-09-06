#!/usr/bin/env bash
# Install services and dependencies based on birdnet.conf
my_dir=$(realpath $(dirname $0))
source $(dirname ${my_dir})/birdnet.conf
HOME=$(sudo -u ${BIRDNET_USER} echo $HOME)
USER=$(sudo -u ${BIRDNET_USER} echo $USER)

install_extraction_service() {
  echo "Installing the extraction.service"
  cat "$(dirname ${my_dir})/templates/extraction.service" \
    > /etc/systemd/system/extraction.service
  cat "$(dirname ${my_dir})/templates/extraction.timer" \
    > /etc/systemd/system/extraction.timer
  if [ ! -z ${REMOTE_RECS_DIR} ];then
    echo "Installing the extraction.service.d/overrides.conf"
    mkdir -p /etc/systemd/system/extraction.service.d
    cat "$(dirname ${my_dir})"/templates/SYSTEMD_overrides.conf \
      > /etc/systemd/system/extraction.service.d/overrides.conf
  fi  
  systemctl enable --now extraction.timer
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
  cat "$(dirname ${my_dir})/templates/birdnet_recording.service" \
    > /etc/systemd/system/birdnet_recording.service
  if [ ! -z ${REMOTE_RECS_DIR} ];then
    echo "Installing the birdnet_recording.service.d/overrides.conf"
    mkdir -p /etc/systemd/system/birdnet_recording.service.d
    cat $(dirname ${my_dir})/templates/SYSTEMD_overrides.conf \
      > /etc/systemd/system/birdnet_recording.service.d/overrides.conf
  fi
  systemctl enable birdnet_recording.service
}

install_sshfs_and_sshkeys() {
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
}

install_systemd_mount() {
  install_sshfs_and_sshkeys
  cat "$(dirname ${my_dir})/templates/SYSTEMD_MOUNT.mount" \
    > /etc/systemd/system/"${SYSTEMD_MOUNT}"
  systemctl enable "${SYSTEMD_MOUNT}"
}

install_avahi_aliases() {
  if ! which avahi-publish &> /dev/null; then
    echo "Installing avahi-utils"
    apt install -y avahi-utils &> /dev/null
  fi
  echo "Installing avahi-alias service"
  cat "$(dirname ${my_dir})/templates/avahi_alias@.service" \
    > /etc/systemd/system/avahi-alias@.service
systemctl enable --now avahi-alias@birdnetsystem.local.service
systemctl enable --now avahi-alias@birdlog.local.service
systemctl enable --now avahi-alias@extractionlog.local.service
systemctl enable --now avahi-alias@birdstats.local.service
}

install_gotty_services() {
  if ! which gotty &> /dev/null;then
    wget -c ${gotty_url} -O - |  tar -xz -C /usr/local/bin/
  fi
  sudo -u ${BIRDNET_USER} ln -sf $(dirname ${my_dir})/templates/gotty \
    $(cat /etc/passwd | grep "${BIRDNET_USER}" | cut -d":" -f6)/.gotty
  cat "$(dirname ${my_dir})/templates/birdnet_log.service" \
    > /etc/systemd/system/birdnet_log.service
  systemctl enable --now birdnet_log.service
  cat "$(dirname ${my_dir})/templates/extraction_log.service" \
    > /etc/systemd/system/extraction_log.service
  systemctl enable --now extraction_log.service
  cat "$(dirname ${my_dir})/templates/birdstats.service" \
    > /etc/systemd/system/birdstats.service
  systemctl enable --now birdstats.service
  cat "$(dirname ${my_dir})/templates/birdterminal.service" \
    > /etc/systemd/system/birdterminal.service
  systemctl enable --now birdterminal.service
}

config_ICECAST() {
  if [ -f /etc/icecast2/icecast.xml ];then 
    cp /etc/icecast2/icecast.xml{,.prebirdnetsystem}
  fi
  sed -i 's/>admin</>birdnet</g' /etc/icecast2/icecast.xml
  passwords=("source-" "relay-" "admin-" "master-" "")
  for i in "${passwords[@]}";do
    sed -i "s/<${i}password>.*<\/${i}password>/<${i}password>${ICE_PWD}<\/${i}password>/g" /etc/icecast2/icecast.xml
  done
}

install_ICECAST() {
  if ! which icecast2;then
    echo "Installing IceCast2"
    apt update &> /dev/null
    echo "icecast2 icecast2/icecast-setup boolean false" | debconf-set-selections
    apt install -qy icecast2 &> /dev/null
    config_ICECAST
    systemctl enable --now icecast2
    /etc/init.d/icecast2 start
  else
    echo "Icecast2 is installed"
    config_ICECAST
    systemctl enable --now icecast2
    /etc/init.d/icecast2 start
  fi
}

install_caddy() {
  if ! which caddy &> /dev/null ;then
    echo "Installing Caddy"
    curl -1sLf \
      'https://dl.cloudsmith.io/public/caddy/stable/setup.deb.sh' \
      | sudo -E bash
    apt update &> /dev/null 
    apt install -y caddy &> /dev/null
  else
    echo "Caddy is installed"
  fi
  echo "Hashing your stream password"
  HASHWORD=$(caddy hash-password -plaintext ${STREAM_PWD})
  [ -d /etc/caddy ] || mkdir /etc/caddy
  echo "Copying the BirdNET-system Extractions index.html"
  cp $(dirname ${my_dir})/templates/index.html ${EXTRACTED}/
  echo "Installing the BirdNET-system Caddyfile"
  if [ -z ${STREAM_PWD} ];then
    cat $(dirname ${my_dir})/templates/Caddyfile_nostream \
      > /etc/caddy/Caddyfile
  else
    cat $(dirname ${my_dir})/templates/Caddyfile_withstream \
      > /etc/caddy/Caddyfile
  fi
  if [ ! -z ${REMOTE_RECS_DIR} ];then
    echo "Installing the caddy.service.d/overrides.conf"
    mkdir -p /etc/systemd/system/caddy.service.d
    cat $(dirname ${my_dir})/templates/SYSTEMD_overrides.conf \
      > /etc/systemd/system/caddy.service.d/overrides.conf
  fi
  systemctl daemon-reload
  systemctl enable --now caddy
}
