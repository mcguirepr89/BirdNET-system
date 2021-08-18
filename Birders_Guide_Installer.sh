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

if [ -z ${LATITUDE} ] || [ -z ${LONGITUDE} ] ;then
  echo "It looks like you haven't filled out the Birders_Guide_Installer_Configuration.txt file

Open that file to edit it. (Go to the folder icon in the top left and look for the \"BirdNET-system\"
folder and double-click the file called \"Birders_Guide_Installer_Configuration.txt\"
Enter the latitude and longitude of where the BirdNET-system will be. 
You can find this at information at https://maps.google.com

Find your location on the map and right click to find your coordinates.
After you have filled out the configuration file, you can re-run this script. Just do the exact
same things you did to start this (copying and pasting from the Wiki) to try again.

Good luck!"
  exit 1
fi

if [ -z ${PUSHED_APP_SECRET} ] || [ -z ${PUSHED_APP_KEY} ];then
  ./scripts/install_birdnet.sh << EOF
ypi
/home/pi/BirdSongs
${LONGITUDE}
${LATITUDE}
yyyhttp://localhost
n
yes
n
EOF
else
  ./scripts/install_birdnet.sh << EOF
ypi
/home/pi/BirdSongs
${LONGITUDE}
${LATITUDE}
yyyhttp://localhost
y${PUSHED_APP_SECRET}
${PUSHED_APP_KEY}
yes
n
EOF
fi
echo "Thanks for installing BirdNET-system!!! The next time you power on the raspberry pi,
all of the services will start up automatically. Visit http://raspberrypi.local or
http://rapsberrypi.lan or http://raspberrypi.lan1 to see the extractions."
