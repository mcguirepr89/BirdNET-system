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
computer is updated properly.

Installing stage 2 installation script now."
  curl -s -O "https://raw.githubusercontent.com/mcguirepr89/BirdNET-system/BirdNET-system-for-raspi4/Birders_Guide_Installer.sh"
  chmod +x Birders_Guide_Installer.sh
  echo "Updating your system. This step will almost definitely take a little while."
  sudo apt -qq update
  sudo apt -qqy upgrade
  echo "Installing git"
  sudo apt install -qqy git
  echo "Stage 1 complete."
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
    echo "Switching to the BirdNET-system-for-raspi4 branch"
    cd BirdNET-system && git checkout BirdNET-system-for-raspi4 > /dev/null
  fi

  if [ -f ${my_dir}/Birders_Guide_Installer_Configuration.txt ];then
    echo "Follow the instructions to fill out the ${LATITUDE} and ${LONGITUDE} variable
and set the passwords for the live audio stream. Save the file after editing
and then close the Mouse Pad editing window"
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

  if [ -z ${PUSHED_APP_SECRET} ] || [ -z ${PUSHED_APP_KEY} ];then
    ${my_dir}/scripts/install_birdnet.sh << EOF
ypi
/home/pi/BirdSongs
${LATITUDE}
${LONGITUDE}
yyyhttp://raspberrypi.local
n
n
EOF
  else
    ${my_dir}/scripts/install_birdnet.sh << EOF
ypi
/home/pi/BirdSongs
${LATITUDE}
${LONGITUDE}
yyyhttp://raspberrypi.local
y${PUSHED_APP_SECRET}
${PUSHED_APP_KEY}
n
EOF
  fi
  echo "Thanks for installing BirdNET-system!!! The next time you power on the raspberry pi,
all of the services will start up automatically. 

The installation has finished. Press Enter to close this window."
  read
}

if [ ! -f ${HOME}/stage_1_complete ] ;then
  stage_1
else
  stage_2
  rm ${HOME}/Birders_Guide_Installer.sh
fi  
