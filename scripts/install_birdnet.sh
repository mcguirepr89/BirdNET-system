#!/usr/bin/env bash
# Install BirdNET script
#set -x # debuggings
trap 'echo -e "\n\nExiting the installation. Goodbye!" && exit' SIGINT
my_dir=$(realpath $(dirname $0))
cd $my_dir || exit 1
#Install/Configure /etc/birdnet/birdnet.conf

sudo ./install_systemd.sh || exit 1
source /etc/birdnet/birdnet.conf

[ -d ${RECS_DIR} ] || mkdir -p ${RECS_DIR}

LASAG="https://github.com/Lasagne/Lasagne/archive/master.zip"
THEON="https://raw.githubusercontent.com/Lasagne/Lasagne/master/requirements.txt"
CONDA="https://github.com/jjhelmus/conda4aarch64/releases/download/1.0.0/c4aarch64_installer-1.0.0-Linux-aarch64.sh"
APT_DEPS=(git ffmpeg wget)
LIBS_MODULES=(libblas-dev liblapack-dev llvm-9)

echo "This script will do the following:
#1: Install the following BirdNET system dependencies:
	- ffmpeg
	- libblas-dev
	- liblapack-dev
	- alsa-utils (for recording)
	- sshfs (to mount remote sound file directories)
#2: Creates a python virtual environment to install BirdNET site-packages:
#3: Builds BirdNET in the 'birdnet' virtual environment.
#4: Copies the systemd .service and .mount files and enables those chosen.
#6: Adds cron environments and jobs chosen."

echo
read -sp \
  "If you DO NOT want to install BirdNET and the birdnet_analysis.service, 
press Ctrl+C to cancel. If you DO wish to install BirdNET and the 
birdnet_analysis.service, press ENTER to continue with the installation."
echo
echo
echo "Checking dependencies"
sudo apt -qqq update
for i in "${LIBS_MODULES[@]}";do
  if [ $(apt list --installed 2>/dev/null | grep "$i" | wc -l) -le 0 ];then
    echo "Installing $i"
    sudo apt -qqqy install $i
  else
    echo "$i is installed!"
  fi
done

for i in "${APT_DEPS[@]}";do
  if ! which $i &>/dev/null ;then
    echo "Installing $i"
    sudo apt -y install $i
  else
    echo "$i is installed!"
  fi
done

if [ -f /bin/llvm-config-9 ];then
  sudo ln -sf /bin/llvm-config-9 /bin/llvm-config
fi

cd ~/BirdNET-system || exit 1
if [ ! -f "model/BirdNET_Soundscape_Model.pkl" ];then
 sh model/fetch_model.sh
fi
wget -O ./scripts/install_conda.sh "${CONDA}"
bash ./scripts/install_conda.sh 
source ${HOME}/c4aarch64_installer/etc/profile.d/conda.sh
conda config --add channels conda-forge
conda update -y conda
conda config --set channel_priority strict
conda create -y --name birdnet numpy scipy future
conda activate birdnet
pip install --upgrade pip wheel setuptools
pip install librosa
pip install -r "$THEON"
pip install "$LASAG"

echo "BirdNet is finished installing!!"
echo
echo "To start the service manually, issue: \
'sudo systemctl start birdnet_analysis'
To monitor the service logs, issue: \
'journalctl -fu birdnet_analysis'
To stop the service manually, issue: \
'sudo systemctl stop birdnet_analysis'
To stop and disable the service, issue: \
'sudo systemctl disable --now birdnet_analysis.service'"
echo
echo "Enabling birdnet_analysis.service now"
sudo systemctl enable birdnet_analysis.service
echo "BirdNET is enabled."
read -n1 -p "Would you like to run the BirdNET service now?" YN
case $YN in
  [Yy] ) sudo systemctl start birdnet_analysis.service \
	   && journalctl -fu birdnet_analysis;;
     * ) echo "Thanks for installing BirdNET-system!!
 I hope it was helpful!"; exit;;
esac
