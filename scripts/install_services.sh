#!/usr/bin/env bash
# Creates and installs the systemd scripts and birdnet configuration file
#set -x # Uncomment to enable debugging
trap 'rm -f ${TMPFILE}' EXIT
my_dir=$(realpath $(dirname $0))
TMPFILE=$(mktemp)
gotty_url="https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz"
CONFIG_FILE="$(dirname ${my_dir})/Birders_Guide_Installer_Configuration.txt"

ln -sf ${my_dir}/* /usr/local/bin/

interactive_config_question() {
  read -n1 -p "Would you like to fill out the configuration file interactively?" YN
  echo
  case $YN in
    [Yy] ) fill_out_config;;
    * ) be_sure_config_exists;;
  esac
}

be_sure_config_exists() {
  read -n1 -p "Have you already filled out birdnet.conf??" YN
  echo
  case $YN in
    [Yy] ) echo "Then take a look at what the installation will do before running the script. Have fun!";exit 0;;
    * ) echo "Sorry, the configuration file has to be filled out for things to work properly. Exiting now"; exit 1;;
  esac
}

fill_out_config() {
  echo "The next few questions will populate the required configuration file."
  echo
  get_BIRDNET_USER
  get_RECS_DIR
  get_GEO
  # Change to templates directory to install services and crontabs
  cd $my_dir || exit 1
  cd ../templates || exit 1
  get_REMOTE
  get_EXTRACTIONS
  get_EXTRACTIONS_URL
  get_PUSHED
  # Change to BirdNET-system directory to install birdnet.conf
  cd $my_dir || exit 1
  cd .. || exit 1
  cat << EOF > ./birdnet.conf
#!/usr/bin/env bash
# Configuration settings for BirdNET as a service
BIRDNET_USER=${BIRDNET_USER}
RECS_DIR=${RECS_DIR}
LATITUDE="${LATITUDE}"
LONGITUDE="${LONGITUDE}"
STREAM_PWD=${STREAM_PWD}
ICE_PWD=${ICE_PWD}

# Defaults
REC_CARD=$(sudo -u ${BIRDNET_USER} aplay -L | awk -F, '/dsn/ {print $1}' | grep -ve 'vc4' -e 'Head' -e 'PCH' | uniq)
#  This is where BirdNet moves audio and selection files after they have been
#  analyzed.
ANALYZED=${RECS_DIR}/*/*Analyzed
#  This is where the formerly 'Analyzed' files are moved after extractions have
#  been made from them. This includes both WAVE and BirdNET.Selection.txt files
PROCESSED=${RECS_DIR}/Processed
#  This is the directory where the extracted audio is moved.
EXTRACTED=${RECS_DIR}/Extracted
IDFILE=$(dirname ${my_dir})/IdentifiedSoFar.txt
OVERLAP="0.0"
CONFIDENCE="0.7"
# Set these if the recordings will be mounted from a remote directory using SSHFS
REMOTE_USER=${REMOTE_USER}
REMOTE_HOST=${REMOTE_HOST}
REMOTE_RECS_DIR=${REMOTE_RECS_DIR}
# This is the URL where the extractions will be web-hosted. Use 'localhost' if
# not making this public.
EXTRACTIONS_URL=${EXTRACTIONS_URL}
# Pushed.co App Key and App Secret
PUSHED_APP_KEY=${PUSHED_APP_KEY}
PUSHED_APP_SECRET=${PUSHED_APP_SECRET}
# Don't touch these
SYSTEMD_MOUNT=$(echo ${RECS_DIR#/} | tr / -).mount
VENV=$(dirname ${my_dir})/birdnet
EOF
}

get_BIRDNET_USER() {
  read -p "Who will be the BirdNET user? (use 'whoami' if unsure) " BIRDNET_USER
  #This is called with sudo, so the {USER} has to be set from {BIRDNET_USER}
  USER=${BIRDNET_USER}
  #Likewise with the {HOME} directory
  HOME=$(grep ^$USER /etc/passwd | cut -d':' -f6)
}

get_RECS_DIR() {
  read -p "What is the full path to your recordings directory (locally)? " RECS_DIR
}

get_GEO() {
  read -p "What is the latitude where the recordings were made? " LATITUDE
  read -p "What is the longitude where the recordings were made? " LONGITUDE
}

get_REMOTE() {
  while true;do # Force a Yes or No
    read -n1 -p "Is this device also doing the recording? " YN
    echo
    case $YN in
      [Yy] ) install_alsa;install_recording_service;break;;
      [Nn] ) is_it_remote;break;;
      * ) echo "Sorry! You have to say yes or no!";;
    esac
  done
}

install_alsa() {
  echo "Checking for alsa-utils"
  if which arecord &> /dev/null ;then
    echo "ALSA-Utils installed"
  else
    echo "Installing alsa-utils"
    apt -qqq update &> /dev/null && apt install -y alsa-utils &> /dev/null
  fi
  REMOTE_HOST=
  REMOTE_RECS_DIR=
  REMOTE_USER=
}

install_recording_service() {
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
  systemctl enable birdnet_recording.service
}


is_it_remote() {
  while true; do
    read -n1 -p "Are the recordings mounted on a remote file system?"
    case $YN in
      [Yy] ) echo "Checking for SSHFS to mount remote filesystem"
        if ! which sshfs &> /dev/null ;then
          echo "Installing SSHFS"
          apt -qqq update &> /dev/null && apt install -qqqy sshfs &> /dev/null
        fi
        read -p "What is the remote hostname or IP address for the recorder? " REMOTE_HOST
        read -p "Who is the remote user? " REMOTE_USER
        read -p "What is the absolute path of the recordings directory on the remote host? " REMOTE_RECS_DIR
        setup_sshkeys;break;;
      [Nn] ) break;;
      * ) echo "Please answer Yes or No";;
    esac
  done
}

setup_sshkeys() {
  while true;do
    read -n1 -p "Would you like to set up the ssh-keys now? 
*Note: You will need to do this manually otherwise." YN
    echo
    case $YN in
      [Yy] ) echo "Adding remote host key to ${HOME}/.ssh/known_hosts"
        ssh-keyscan -H ${REMOTE_HOST} >> ${HOME}/.ssh/known_hosts
        chown ${USER}:${USER} ${HOME}/.ssh/known_hosts &> /dev/null
        if [ ! -f ${HOME}/.ssh/id_ed25519.pub ];then
          ssh-keygen -t ed25519 -f ${HOME}/.ssh/id_ed25519 <<EOF



EOF
        fi
        chown -R ${USER}:${USER} ${HOME}/.ssh/ &> /dev/null
        echo "Copying public key to ${REMOTE_HOST}"
        ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST};break;;
      [Nn] ) echo "Be sure to set that up before running birdnet_analysis";break;;
      * ) echo "Sorry! You have to say yes or no!";;
    esac
  done
}

get_EXTRACTIONS() {
  while true;do # Force Yes or No
    read -n1 -p "Do you want this device to perform the extractions? " YN
    echo
    case $YN in
      [Yy] ) echo "Installing the extraction.service"
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
        systemctl enable extraction.service
        echo "Adding the species_updater.cron"
        if ! crontab -u ${BIRDNET_USER} -l &> /dev/null;then
          cd $my_dir || exit 1
          cd ../templates || exit 1
          crontab -u ${BIRDNET_USER} ./species_updater.cron &> /dev/null
        else
          crontab -u ${BIRDNET_USER} -l > ${TMPFILE}
          cd $my_dir || exit 1
          cd ../templates || exit 1
          cat ./species_updater.cron >> ${TMPFILE}
          crontab -u ${BIRDNET_USER} "${TMPFILE}" &> /dev/null
        fi
        break;;
      [Nn] ) break;;
      *  ) echo "You have to answer one way or the other!";;
    esac
  done
}

get_EXTRACTIONS_URL() {
  while true;do
    read -n1 -p "Would you like to access the extractions via a web browser
    *Note: It is recommended, (but not required), that you run the web 
    server on the same host that does the extractions. If the extraction 
    service and web server are on different hosts, the \"By_Species\" and 
    \"Processed\" symbolic links won't work. The \"By-Date\" extractions, 
    however, will work as expected." YN
    echo
    case $YN in
      [Yy] ) read -p "What URL would you like to publish the extractions to?
    *Note: Set this to http://localhost if you do not want to make the 
    extractions publically available: " EXTRACTIONS_URL
        if ! which caddy &> /dev/null ;then
          echo "Installing Caddy"
          curl -1sLf \
            'https://dl.cloudsmith.io/public/caddy/stable/setup.deb.sh' \
              | sudo -E bash
	        apt update &> /dev/null 
          apt install -y caddy &> /dev/null
          systemctl enable --now caddy &> /dev/null
          get_STREAM_PWD
          install_avahi_aliases
	        install_gotty_logs
	      else
          echo "Caddy is installed"
          systemctl enable --now caddy &> /dev/null
          get_STREAM_PWD
          install_avahi_aliases
	        install_gotty_logs
        fi
        break;;
      [Nn] ) EXTRACTIONS_URL=;break;;
      * ) echo "Please answer Yes or No";;
    esac
  done
}

get_STREAM_PWD() {
  if [ -f ${CONFIG_FILE} ];then source ${CONFIG_FILE};fi
  if [ -z ${STREAM_PWD} ]; then
    read -p "Please set a password to protect your live stream: " STREAM_PWD
  fi
  HASHWORD=$(caddy hash-password -plaintext ${STREAM_PWD})
  get_ICE_PWD
}

get_ICE_PWD() {
  if [ -f ${CONFIG_FILE} ];then source ${CONFIG_FILE};fi
  echo $ICE_PWD
  if [ -z $ICE_PWD ] ;then
    while true; do
      read -p "Please set the icecast password. Use only alphanumeric characters. " ICE_PWD
      echo
     case ${ICE_PWD} in
        "" ) echo The password cannot be empty. Please make a password.;;
        * ) install_ICECAST; install_stream_service;break;;
      esac
    done
  else
    install_ICECAST; install_stream_service
  fi
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
    systemctl reenable --now icecast2
    /etc/init.d/icecast2 start
  fi
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

install_stream_service() {
  echo "Installing Live Stream service"
  REC_CARD="$(sudo -u ${BIRDNET_USER} aplay -L | awk -F, '/dsn/ {print $1}' | grep -ve 'vc4' -e 'Head' -e 'PCH' | uniq)"
  cat << EOF > /etc/systemd/system/livestream.service
[Unit]
Description=BirdNET-system Live Stream

[Service]
Environment=XDG_RUNTIME_DIR=/run/usr/1000
Restart=always
Type=simple
RestartSec=3
User=${BIRDNET_USER}
ExecStart=ffmpeg -loglevel 52 -ac 2 -f alsa -i ${REC_CARD} -acodec libmp3lame -b:a 320k -ac 2 -content_type 'audio/mpeg' -f mp3 icecast://source:${ICE_PWD}@localhost:8000/stream -re

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now livestream.service
}

install_avahi_aliases() {
  if ! which avahi-publish &> /dev/null; then
    echo "Installing avahi-utils"
    apt install -y avahi-utils &> /dev/null
  fi
  echo "Installing avahi-alias service"
  cat << 'EOF' > /etc/systemd/system/avahi-alias@.service
[Unit]
Description=Publish %I as alias for %H.local via mdns
After=network.target network-online.target
Requires=network-online.target

[Service]
Restart=always
Type=simple
ExecStart=/bin/bash -c "/usr/bin/avahi-publish -a -R %I $(avahi-resolve -4 -n %H.local | cut -f 2)"

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now avahi-alias@birdnetsystem.local.service
  systemctl enable --now avahi-alias@birdlog.local.service
  systemctl enable --now avahi-alias@extractionlog.local.service
  systemctl enable --now avahi-alias@birdstats.local.service
}

get_PUSHED() {
  while true; do # Force Yes or No
    read -n1 -p "Do you have a free App key to receive mobile notifications via Pushed.co?" YN
    echo
    case $YN in
      [Yy] ) read -p "Enter your Pushed.co App Key: " PUSHED_APP_KEY
        read -p "Enter your Pushed.co App Key Secret: " PUSHED_APP_SECRET
        break;;
      [Nn] ) PUSHED_APP_KEY=
        PUSHED_APP_SECRET=
        break;;
      * ) echo "A simple Yea or Nay will do";;
    esac
  done
}

install_cleanup_cron() {
  echo "Adding the cleanup.cron"
  if ! crontab -u ${BIRDNET_USER} -l &> /dev/null;then
    cd $my_dir || exit 1
    cd ../templates || exit 1
    crontab -u ${BIRDNET_USER} ./cleanup.cron &> /dev/null
  else
    crontab -u ${BIRDNET_USER} -l > ${TMPFILE}
    cd $my_dir || exit 1
    cd ../templates || exit 1
    cat ./cleanup.cron >> ${TMPFILE}
    crontab -u ${BIRDNET_USER} "${TMPFILE}" &> /dev/null
  fi
}

install_gotty_logs() {
  if ! which gotty &> /dev/null;then
  wget -c ${gotty_url} -O - |  tar -xz -C /usr/local/bin/
  fi
  ln -fs $(dirname ${my_dir})/templates/.gotty \
    $(cat /etc/passwd | grep "${BIRDNET_USER}" | cut -d":" -f6)
  cat << EOF > /etc/systemd/system/birdnet_log.service
[Unit]
Description=BirdNET Analysis Log

[Service]
Restart=on-failure
RestartSec=3
Type=simple
User=${BIRDNET_USER}
Environment=TERM=xterm-256color
ExecStart=/usr/local/bin/gotty -p 8080 --title-format "BirdNET-system Log" journalctl -fu birdnet_analysis.service

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now birdnet_log.service
  cat << EOF > /etc/systemd/system/extraction_log.service
[Unit]
Description=BirdNET Extraction Log

[Service]
Restart=on-failure
RestartSec=3
Type=simple
User=${BIRDNET_USER}
Environment=TERM=xterm-256color
ExecStart=/usr/local/bin/gotty -p 8888 --title-format "Extractions Log" journalctl -fu extraction.service

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now extraction_log.service
  cat << EOF > /etc/systemd/system/birdstats.service
[Unit]
Description=BirdNET Statistics Log

[Service]
Restart=on-failure
RestartSec=3
Type=simple
User=${BIRDNET_USER}
Environment=TERM=xterm-256color
ExecStart=/usr/local/bin/gotty -p 9090 --title-format "BirdNET-system Statistics" /usr/local/bin/birdnet_stats.sh

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now birdstats.service
}

finish_installing_services() {
  USER=${BIRDNET_USER}
  HOME=$(grep ^$USER /etc/passwd | cut -d':' -f6)

  [ -d /etc/birdnet ] || mkdir /etc/birdnet
  cd ${my_dir} || exit 1
  ln -fs $(dirname ${my_dir})/birdnet.conf /etc/birdnet/birdnet.conf
  source /etc/birdnet/birdnet.conf
  
  [ -d ${EXTRACTED} ] || sudo -u ${BIRDNET_USER} mkdir -p ${EXTRACTED}
  
  install_cleanup_cron
  
  if [ ! -z "${REMOTE_RECS_DIR}" ];then
    cat << EOF > /etc/systemd/system/${SYSTEMD_MOUNT}
[Unit]
Description=Mount remote fs with sshfs
DefaultDependencies=no
Conflicts=umount.target
After=network-online.target
Before=umount.target
Wants=network-online.target
[Install]
WantedBy=multi-user.target
[Mount]
What=${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_RECS_DIR}
Where=${RECS_DIR}
Type=fuse.sshfs
Options=delay_connect,_netdev,allow_other,IdentityFile=/home/${BIRDNET_USER}/.ssh/id_ed25519,reconnect,ServerAliveInterval=30,ServerAliveCountMax=5,x-systemd.automount,uid=1000,gid=1000
TimeoutSec=60
EOF
    cat << EOF > /etc/systemd/system/birdnet_analysis.service
[Unit]
Description=BirdNET Analysis
Requires=${SYSTEMD_MOUNT}
After=network-online.target ${SYSTEMD_MOUNT}
[Service]
Restart=always
RuntimeMaxSec=10800
Type=simple
RestartSec=3
User=${BIRDNET_USER}
ExecStart=/usr/local/bin/birdnet_analysis.sh
[Install]
WantedBy=multi-user.target
EOF
    systemctl enable "${SYSTEMD_MOUNT}"
  else
    cat << EOF > /etc/systemd/system/birdnet_analysis.service
[Unit]
Description=BirdNET Analysis
[Service]
Restart=always
RuntimeMaxSec=10800
Type=simple
RestartSec=3
User=${BIRDNET_USER}
ExecStart=/usr/local/bin/birdnet_analysis.sh
[Install]
WantedBy=multi-user.target
EOF
  fi

  if [ ! -z "${EXTRACTIONS_URL}" ];then
    [ -d /etc/caddy ] || mkdir /etc/caddy
    sudo -u ${BIRDNET_USER} ln -fs \
      $(dirname ${my_dir})/templates/index.html ${EXTRACTED}/
    cat << EOF > /etc/caddy/Caddyfile
${EXTRACTIONS_URL} {
  root * ${EXTRACTED}
  file_server browse
  basicauth /Processed* {
    birdnet ${HASHWORD}
  }
  basicauth /stream {
    birdnet ${HASHWORD}
  }
  reverse_proxy /stream localhost:8000
}

http://birdnetsystem.local {
  root * ${EXTRACTED}
  file_server browse
  basicauth /Processed* {
    birdnet ${HASHWORD}
  }
  basicauth /stream {
    birdnet ${HASHWORD}
  }
  reverse_proxy /stream localhost:8000
}

http://birdlog.local {
  reverse_proxy localhost:8080
}

http://extractionlog.local {
  reverse_proxy localhost:8888
}

http://birdstats.local {
  reverse_proxy localhost:9090
}

EOF
    if [ ! -z ${REMOTE_USER} ];then
      mkdir -p /etc/systemd/system/caddy.service.d
      cat << EOF > /etc/systemd/system/caddy.service.d/overrides.conf
[Unit]
After=network.target network-online.target ${SYSTEMD_MOUNT}
Requires=network-online.target ${SYSTEMD_MOUNT}
EOF
      systemctl daemon-reload
    fi
    systemctl restart caddy
 fi
}

interactive_config_question
finish_installing_services
