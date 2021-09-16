#!/usr/bin/env bash
set -e
my_dir=${HOME}/BirdNET-system

if [ "$(uname -m)" != "aarch64" ];then
  echo "BirdNET-system requires a 64-bit OS.
It looks like your operating system is using $(uname -m), 
but would need to be aarch64.
Please take a look at https://birdnetwiki.pmcgui.xyz for more
information"
  exit 1
fi

install_zram_swap() {
  echo "Configuring zram.service"
  sudo touch /etc/modules-load.d/zram.conf
  echo 'zram' | sudo tee /etc/modules-load.d/zram.conf
  sudo touch /etc/modprobe.d/zram.conf
  echo 'options zram num_devices=1' | sudo tee /etc/modprobe.d/zram.conf
  sudo touch /etc/udev/rules.d/99-zram.rules
  echo 'KERNEL=="zram0", ATTR{disksize}="4G",TAG+="systemd"' \
    | sudo tee /etc/udev/rules.d/99-zram.rules
  sudo touch /etc/systemd/system/zram.service
  echo "Installing zram.service"
  cat << EOF | sudo tee /etc/systemd/system/zram.service
[Unit]
Description=Swap with zram
After=multi-user.target

[Service]
Type=oneshot 
RemainAfterExit=true
ExecStartPre=/sbin/mkswap /dev/zram0
ExecStart=/sbin/swapon /dev/zram0
ExecStop=/sbin/swapoff /dev/zram0

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl enable zram
}

stage_1() {
  echo "Welcome to the Birders Guide Installer script.
This installer assumes that you have not updated the Raspberry Pi yet.

This will run in two stages. The first stage will simply ensure your
computer is updated properly."

  echo "Updating your system. This step will almost definitely take a little while."
  sudo apt -qq update
  sudo apt -qqy upgrade
  echo "Installing git"
  sudo apt install -qqy git
  echo "Stage 1 complete."
  echo "Installing stage 2 installation script now."
  curl -s -O "https://raw.githubusercontent.com/mcguirepr89/BirdNET-system/rpitesting/Birders_Guide_Installer.sh"
  chmod +x Birders_Guide_Installer.sh
  touch ${HOME}/stage_1_complete
  cat << EOF | sudo tee /etc/systemd/user/birdnet-system-installer.service &> /dev/null
[Unit]
Description=A BirdNET-system Installation Script Service
After=graphical.target network-online.target

[Service]
Type=simple
Restart=on-failure
RestartSec=3s
ExecStart=lxterminal -e /home/pi/Birders_Guide_Installer.sh

[Install]
WantedBy=default.target
EOF
  systemctl --user enable birdnet-system-installer.service
  install_zram_swap
  sudo reboot
}

stage_2() {
  systemctl --user disable birdnet-system-installer.service &> /dev/null
  sudo rm /etc/systemd/user/birdnet-system-installer.service
  rm ${HOME}/stage_1_complete
  export DISPLAY=:0
  echo "Welcome back! Waiting for an internet connection to continue"
  until ping -c 1 google.com &> /dev/null; do
    sleep 1
  done
  echo "Connected!"
  if [ ! -d ${my_dir} ];then
    cd ~ || exit 1
    echo "Cloning the BirdNET-system repository in your home directory"
    git clone https://github.com/mcguirepr89/BirdNET-system.git
    echo "Switching to the rpitesting branch"
    cd BirdNET-system && git checkout rpitesting > /dev/null
  fi

  if [ -f ${my_dir}/Birders_Guide_Installer_Configuration.txt ];then
    echo "Follow the instructions to fill out the ${LATITUDE} and ${LONGITUDE} variable
and set the passwords for the live audio stream. Save the file after editing
and then close the Mouse Pad editing window to continue."
    mousepad ${my_dir}/Birders_Guide_Installer_Configuration.txt &> /dev/null
    while pgrep mouse &> /dev/null;do
      sleep 1
    done
    source ${my_dir}/Birders_Guide_Installer_Configuration.txt
  else
    echo "Something went wrong. I can't find the configuration file."
    exit 1
  fi

  if [ -z ${LATITUDE} ] || [ -z ${LONGITUDE} ] || [ -z ${STREAM_PWD} ] || [ -z ${ICE_PWD} ];then
    echo "It looks like you haven't filled out the Birders_Guide_Installer_Configuration.txt file
completely.
Open that file to edit it. (Go to the folder icon in the top left and look for the \"BirdNET-system\"
folder and double-click the file called \"Birders_Guide_Installer_Configuration.txt\"
Enter the latitude and longitude of where the BirdNET-system will be. 
You can find this information at https://maps.google.com

Find your location on the map and right click to find your coordinates.
After you have filled out the configuration file, you can re-run this script. Just do the exact
same things you did to start this (copying and pasting from the Wiki) to try again.

Good luck!"
    exit 1
  fi

  install_birdnet_config || exit 1
  ${my_dir}/scripts/new_install_birdnet.sh || exit 1

  echo "Thanks for installing BirdNET-system!!! The next time you power on the raspberry pi,
all of the services will start up automatically. 

The installation has finished. Press Enter to close this window."
  read
}

install_birdnet_config() {
  cat << EOF > ${my_dir}/birdnet.conf
################################################################################
#                 Configuration settings for BirdNET as a service              #
################################################################################

#___________The four variables below are the only that are required.___________#

## BIRDNET_USER should be the non-root user systemd should use to execute each 
## service.

BIRDNET_USER=pi

## RECS_DIR is the location birdnet_analysis.service will look for the data-set
## it needs to analyze. Be sure this directory is readable and writable for
## the BIRDNET_USER. If you are going to be accessing a remote data-set, you
## still need to set this, as this will be where the remote directory gets
## mounted locally. See REMOTE_RECS_DIR below for mounting remote data-sets.

RECS_DIR=${HOME}/BirdSongs

## LATITUDE and LONGITUDE are self-explanatroy. Find them easily at
## maps.google.com. Only go to the thousanths place for these variables
##  Example: these coordinates would indicate the Eiffel Tower in Paris, France.
##  LATITUDE=48.858
##  LONGITUDE=2.294

LATITUDE="${LATITUDE}"
LONGITUDE="${LONGITUDE}"

################################################################################
#------------------------------ Extraction Service  ---------------------------#

#   Keep this EMPTY if you do not want this device to perform the extractions  #

## DO_EXTRACTIONS is simply a setting for enabling the extraction.service.
## Set this to Y or y to enable extractions.

DO_EXTRACTIONS=y

################################################################################
#-----------------------------  Recording Service  ----------------------------#

#   Keep this EMPTY if you do not want this device to perform the recording.   #

## DO_RECORDING is simply a setting for enabling the 24/7 birdnet_recording.service.
## Set this to Y or y to enable recording.

DO_RECORDING=y

################################################################################
#-----------------  Mounting a remote directory with systemd  -----------------#
#_______________The four variables below can be set to enable a_______________#
#___________________systemd.mount for analysis, extraction,____________________#
#______________________________or file-serving_________________________________#

#            Leave these settings EMPTY if your data-set is local.             #

## REMOTE is simply a setting for enabling the systemd.mount to use a remote 
## filesystem for the data storage and service.
## Set this to Y or y to enable the systemd.mount. 

REMOTE=

## REMOTE_HOST is the IP address, hostname, or domain name SSH should use to 
## connect for FUSE to mount its remote directories locally.

REMOTE_HOST=

## REMOTE_USER is the user SSH will use to connect to the REMOTE_HOST.

REMOTE_USER=

## REMOTE_RECS_DIR is the directory on the REMOTE_HOST which contains the
## data-set SSHFS should mount to this system for local access. This is NOT the
## directory where you will access the data on this machine. See RECS_DIR for
## that.

REMOTE_RECS_DIR=

################################################################################
#-----------------------  Web-hosting/Caddy File-server -----------------------#
#__________The two variables below can be set to enable web access_____________#
#____________to your data,(e.g., extractions, raw data, live___________________#
#______________audio stream, BirdNET.selection.txt files)______________________#

#         Leave these EMPTY if you do not want to enable web access            #

## EXTRACTIONS_URL is the URL where the extractions, data-set, and live-stream
## will be web-hosted. If you do not own a domain, or would just prefer to keep 
## BirdNET-system on your local network, you can set this to http://localhost.
## Setting this (even to http://localhost) will also allow you to enable the   
## GoTTY web logging features below.

EXTRACTIONS_URL=http://localhost

## CADDY_PWD is the plaintext password (that will be hashed) and used to access
## the "Processed" directory and live audio stream. This MUST be set if you
## choose to enable this feature.

CADDY_PWD=${CADDY_PWD}

################################################################################
#-------------------------  Live Audio Stream  --------------------------------#
#_____________The variable below configures/enables the live___________________# 
#_____________________________audio stream.____________________________________#

#         Keep this EMPTY if you do not wish to enable the live stream         #
#                or if this device is not doing the recording                  #

## ICE_PWD is the password that icecast2 will use to authenticate ffmpeg as a
## trusted source for the stream. You will never need to enter this manually
## anywhere other than here.

ICE_PWD=${ICE_PWD}

################################################################################
#-------------------  Mobile Notifications via Pushed.co  ---------------------#
#____________The two variables below enable mobile notifications_______________#
#_____________See https://pushed.co/quick-start-guide to get___________________#
#_________________________these values for your app.___________________________#

#            Keep these EMPTY if haven't setup a Pushed.co App yet.            #

## Pushed.co App Key and App Secret

PUSHED_APP_KEY=${PUSHED_APP_KEY}
PUSHED_APP_SECRET=${PUSHED_APP_SECRET}

################################################################################
#--------------------------------  Defaults  ----------------------------------#
#______The six variables below are default settings that you (probably)________#
#__________________don't need to change at all, but can._______________________# 

## REC_CARD is the sound card you would want the birdnet_recording.service to 
## use. This setting is irrelevant if you are not planning on doing data 
## collection via recording on this machine. The command substitution below 
## looks for a USB microphone's dsnoop alsa device. The dsnoop device lets
## birdnet_recording.service and livestream.service share the raw audio stream
## from the microphone. If you would like to use a different microphone than
## what this produces, or if your microphone does not support creating a
## dsnoop device, you can set this explicitly from a list of the available
## devices from the output of running 'aplay -L'

REC_CARD="\$(sudo -u ${BIRDNET_USER} aplay -L \
  | awk -F, '/dsn/ {print $1}' \
  | grep -ve 'vc4' -e 'Head' -e 'PCH' \
  | uniq)"

## PROCESSED is the directory where the formerly 'Analyzed' files are moved 
## after extractions have been made from them. This includes both WAVE and 
## BirdNET.selection.txt files.

PROCESSED=${RECS_DIR}/Processed

## EXTRACTED is the directory where the extracted audio selections are moved.

EXTRACTED=${RECS_DIR}/Extracted

## IDFILE is the file that keeps a complete list of every spececies that
## BirdNET has identified from your data-set. It is persistent across
## data-sets, so would need to be whiped clean through deleting or renaming
## it. A backup is automatically made from this variable each time it is 
## updated (structure: ${IDFILE}.bak), and would also need to be removed
## or renamed to start a new file between data-sets. Alternately, you can
## change this variable between data-sets to preserve records of disparate
## data-sets according to name.

IDFILE=${HOME}/BirdNET-system/IdentifiedSoFar.txt

## OVERLAP is the value in seconds which BirdNET should use when analyzing
## the data. The values must be between 0.0-2.9.

OVERLAP="0.0"

## CONFIDENCE is the minimum confidence level from 0.0-1.0 BirdNET's analysis 
## should reach before creating an entry in the BirdNET.selection.txt file.
## Don't set this to 1.0 or you won't have any results.

CONFIDENCE="0.7"

################################################################################
#------------------------------  Auto-Generated  ------------------------------#
#_______________The three variables below are auto-generated___________________#
#______________________________during installation_____________________________#

# Don't touch these

## ANALYZED is where the extraction.service looks for audio and 
## BirdNET.selection.txt files after they have been processed by the 
## birdnet_analysis.service. This is NOT where the analyzed files are moved -- 
## analyzed files are always created within the same directory 
## birdnet_analysis.service finds them.

ANALYZED=${RECS_DIR}/*/*Analyzed

## SYSTEMD_MOUNT is created from the RECS_DIR variable to comply with systemd 
## mount naming requirements.

SYSTEMD_MOUNT=$(echo ${RECS_DIR#/} | tr / -).mount

## VENV is the virtual environment where the the BirdNET python build is found,
## i.e, VENV is the virtual environment miniforge built for BirdNET.

VENV=${my_dir}/miniforge/envs/birdnet
EOF
  [ -d /etc/birdnet ] || sudo mkdir /etc/birdnet
  sudo ln -sf ${my_dir}/birdnet.conf /etc/birdnet/birdnet.conf
}

if [ ! -f ${HOME}/stage_1_complete ] ;then
  stage_1
else
  stage_2
  rm ${HOME}/Birders_Guide_Installer.sh
fi  

