#!/usr/bin/env bash
# Install BirdNET script
#set -x # debugging
set -e # exit installation if anything fails
trap 'echo -e "\n\nExiting the installation. Goodbye!" && exit' SIGINT
my_dir=$(realpath $(dirname $0))
cd $my_dir || exit 1

if [ "$(uname -m)" != "aarch64" ];then
  echo "BirdNET-system requires a 64-bit OS.
It looks like your operating system is using $(uname -m), 
but would need to be aarch64.
Please take a look at https://birdnetwiki.pmcgui.xyz for more
information"
  exit 1
fi

#Install/Configure /etc/birdnet/birdnet.conf
./new_install_config.sh || exit 1
sudo ./new_install_services.sh || exit 1
source /etc/birdnet/birdnet.conf

LASAG="https://github.com/Lasagne/Lasagne/archive/master.zip"
THEON="https://raw.githubusercontent.com/Lasagne/Lasagne/master/requirements.txt"
CONDA="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh"
APT_DEPS=(ffmpeg wget)
LIBS_MODULES=(libblas-dev liblapack-dev llvm-9)

install_deps() {
  echo "	Checking dependencies"
  sudo apt update &> /dev/null
  for i in "${LIBS_MODULES[@]}";do
    if [ $(apt list --installed 2>/dev/null | grep "$i" | wc -l) -le 0 ];then
      echo "	Installing $i"
      sudo apt -y install ${i} &> /dev/null
    else
      echo "	$i is installed!"
    fi
  done

  for i in "${APT_DEPS[@]}";do
    if ! which $i &>/dev/null ;then
      echo "	Installing $i"
      sudo apt -y install ${i} &> /dev/null
    else
      echo "	$i is installed!"
    fi
  done

  if [ -f /bin/llvm-config-9 ];then
    echo "	Making symbolic link for llvm-config binary"
    sudo ln -sf /bin/llvm-config-9 /bin/llvm-config &> /dev/null
  fi
}

install_birdnet() {
  set -e
  cd ~/BirdNET-system || exit 1
  if [ ! -f "model/BirdNET_Soundscape_Model.pkl" ];then
    echo "	Fetching the model"
    sh model/fetch_model.sh > /dev/null 
  fi
  if [ ! -f "./scripts/install_miniforge.sh" ];then
    echo "	Fetching the Miniforge3 installation script"
    wget -O ./scripts/install_miniforge.sh "${CONDA}" &> /dev/null
  fi
  echo "	Installing Miniforge3 for aarch64"
  bash ./scripts/install_miniforge.sh \
    -b -p$(dirname ${my_dir})/miniforge > /dev/null
      echo "	Initializing Miniforge (conda)"
  source $(dirname ${my_dir})/miniforge/etc/profile.d/conda.sh
  echo "	Initializing the birdnet virtual environment with
            - numba
            - numpy
            - scipy
            - future
            - python=3.7"
  conda create -y --name birdnet \
    numba numpy scipy future python=3.7 &> /dev/null
  echo "	Activating new environment"
  conda activate birdnet > /dev/null 
  echo "	Upgrading pip, wheel, and setuptools"
  pip install --upgrade pip wheel setuptools > /dev/null 
  echo "	Installing Librosa"
  pip install librosa > /dev/null 
  echo "	Installing Theano"
  pip install -r "$THEON" > /dev/null 
  echo "	Installing Lasagne"
  pip install "$LASAG" > /dev/null 
}

echo "
This script will do the following:
#1: Install the following BirdNET system dependencies:
- ffmpeg
- libblas-dev
- liblapack-dev
- wget
- llvm-9
#2: Creates a conda virtual environment for BirdNET
#3: Builds BirdNET in the 'birdnet' conda virtual environment
#4: Copies the systemd .service and .mount files and enables those chosen
#5: Adds cron environments and jobs chosen"

echo
read -sp "\
Be sure you have read the software license before installing. This is
available in the BirdNET-system directory as "LICENSE"
If you DO NOT want to install BirdNET and the birdnet_analysis.service, 
press Ctrl+C to cancel. If you DO wish to install BirdNET and the 
birdnet_analysis.service, press ENTER to continue with the installation."
echo
echo

[ -d ${RECS_DIR} ] || mkdir -p ${RECS_DIR} &> /dev/null

install_deps
if [ ! -d ${VENV} ];then
  install_birdnet 
fi

echo "	BirdNet is installed!!"
echo "	Enabling birdnet_analysis.service now"
sudo systemctl enable birdnet_analysis.service
echo "	BirdNET is enabled."
echo
echo "	To start the service manually, issue:
            'sudo systemctl start birdnet_analysis'
        To monitor the service logs, issue: 
            'journalctl -fu birdnet_analysis'
        To stop the service manually, issue: 
            'sudo systemctl stop birdnet_analysis'
        To stop and disable the service, issue: 
            'sudo systemctl disable --now birdnet_analysis.service'

      Visit
      http://birdnetsystem.local to see your extractions,
      http://birdlog.local to see the log output of the birdnet_analysis.service,
      http://extractionlog.local to see the log output of the extraction.service, and
      http://birdstats.local to see the BirdNET-system Report"
echo
read -n1 -p "  Would you like to run the BirdNET service now?" YN
echo
case $YN in
  [Yy] ) sudo systemctl start birdnet_analysis.service \
    && journalctl -fu birdnet_analysis;;
* ) echo "  Thanks for installing BirdNET-system!!
  I hope it was helpful!"; exit;;
esac
