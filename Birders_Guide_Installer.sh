#!/usr/bin/env bash
my_dir=${HOME}/BirdNET-system


if ! which git &> /dev/null ;then
  echo "Installing git"
  sudo apt update &> /dev/null && sudo apt install -y git &> /dev/null
fi

if [ ! -d ${my_dir} ];then
  cd ~ || exit 1
  echo "Cloning the BirdNET-system repository in your home directory"
  git clone https://github.com/mcguirepr89/BirdNET-system.git 
  echo "Switching to the BirdNET-system-for-raspi4 branch"
  cd BirdNET-system && git checkout BirdNET-system-for-raspi4
fi

if [ -f ${my_dir}/Birders_Guide_Installer_Configuration.txt ];then
  source ${my_dir}/Birders_Guide_Installer_Configuration.txt
else
  echo "Something went wrong. I can't find the configuration file."
  exit 1
fi

if [ -z ${LATITUDE} ] || [ -z ${LONGITUDE}] ;then
  echo "It looks like you haven't filled out the Birders_Guide_Installer_Configuration.txt file

Open that file to edit it.
You can right-click this link ---> file:/BirdNET-system/Birders_Guide_Installer_Configuration.txt
and select \"Open\". Enter the latitude and longitude of where the BirdNET-system will be. 
You can find this at information at https://maps.google.com

Find your location on the map and right click to find your coordinates.
After you have filled out the configuration file, you can re-run this script. Just do the exact
same things you did to start this (copying and pasting from the Wiki) to try again.

Good luck!"
  exit 1
fi

./scripts/install_birdnet.sh << EOF
ypi
/home/pi/BirdSongs
${LONGITUDE}
${LATITUDE}
yyyhttp://localhost
yes
n
EOF
