#!/usr/bin/env bash
# Install BirdNET script
trap 'echo -e "\n\nExiting the installation. Goodbye!" && exit' SIGINT
my_dir=$(realpath $(dirname $0))
cd $my_dir || exit 1

#Install/Configure /etc/birdnet/birdnet.conf
sudo ./install_services.sh || exit 1
source /etc/birdnet/birdnet.conf

LASAG="https://github.com/Lasagne/Lasagne/archive/master.zip"
THEON="https://raw.githubusercontent.com/Lasagne/Lasagne/master/requirements.txt"
APT_DEPS=(ffmpeg wget)
LIBS_MODULES=(python3-pip python3-venv libblas-dev liblapack-dev)

spinner() {
  pid=$! # Process Id of the previous running command
  spin='-\|/'
  i=0

  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1}"
    sleep .1
  done
}


install_deps() {
  echo "	Checking dependencies "
  sudo apt update &> /dev/null
  for i in "${LIBS_MODULES[@]}";do
    if [ $(apt list --installed 2>/dev/null | grep "$i" | wc -l) -le 0 ];then
      echo "	Installing $i "
      sudo apt -y install $i &> /dev/null
    else
      echo "	$i is installed!"
    fi
  done 

  for i in "${APT_DEPS[@]}";do
    if ! which $i &>/dev/null ;then
      echo "	Installing $i "
      sudo apt -y install $i &> /dev/null
    else
      echo "	$i is installed!"
    fi
  done
}

installation() {
  echo "	Installing BirdNET "
  cd $my_dir || exit 1
  cd .. || exit 1
  echo "	Setting up the birdnet  virtual environment "
  python3 -m venv birdnet 
  source ./birdnet/bin/activate
  if [ ! -f "model/BirdNET_Soundscape_Model.pkl" ];then
    echo "	Fetching the model "
    sh model/fetch_model.sh &> /dev/null
  fi
  echo "	Updating pip, wheel, and setuptools "
  pip3 install --upgrade pip wheel setuptools &> /dev/null
  echo "	Installing numpy, scipy, librosa, and future "
  pip3 install -r requirements.txt &> /dev/null
  echo "	Installing Theano "
  pip3 install -r "$THEON" &> /dev/null
  echo "	Installing Lasagne "
  pip3 install "$LASAG" &> /dev/null
}

# START

echo "	This script will do the following:
  #1: Install the following BirdNET system dependencies:
        - ffmpeg
        - python3-venv
        - python3-pip
        - libblas-dev
        - liblapack-dev
        - alsa-utils (for recording)
        - sshfs (to mount remote sound file directories)
  #2: Creates a python virtual environment for BirdNET
  #3: Builds BirdNET in the 'birdnet' virtual environment
  #4: Copies the systemd .service and .mount files and enables those chosen
  #5: Adds cron environments and jobs chosen"

echo
read -sp \
  " If you DO NOT want to install BirdNET and the birdnet_analysis.service,
  press Ctrl+C to cancel. If you DO wish to install BirdNET and the 
  birdnet_analysis.service, press ENTER to continue with the 
  installation."
echo
echo

[ -d ${RECS_DIR} ] || mkdir -p ${RECS_DIR} &> /dev/null
install_deps & spinner
installation & spinner

echo "	BirdNet is finished installing!!"
echo
echo "	To start the service manually, issue:
  'sudo systemctl start birdnet_analysis'
  To monitor the service logs, issue:
  'journalctl -fu birdnet_analysis'
  To stop the service manually, issue:
  'sudo systemctl stop birdnet_analysis'
  To stop and disable the service, issue:
  'sudo systemctl disable --now birdnet_analysis.service'"
echo
echo "	Enabling birdnet_analysis.service now"
sudo systemctl enable birdnet_analysis.service
echo "	BirdNET is enabled."
read -n1 -p "	Would you like to run the BirdNET service now?" YN
case $YN in
  [Yy] ) sudo systemctl start birdnet_analysis.service \
    && journalctl -fu birdnet_analysis;;
* ) echo "	Thanks for installing BirdNET-system!!
  I hope it was helpful!"; exit;;
esac
