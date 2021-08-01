#!/usr/bin/env bash
# Install BirdNET script
#set -x # debuggings
trap 'echo -e "\n\nExiting the installation. Goodbye!" && exit' SIGINT
my_dir=$(realpath $(dirname $0))
cd $my_dir || exit 1
#Install/Configure /etc/birdnet/birdnet.conf
sudo ./install_systemd.sh || exit 1
source /etc/birdnet/birdnet.conf

LASAG="https://github.com/Lasagne/Lasagne/archive/master.zip"
THEON="https://raw.githubusercontent.com/Lasagne/Lasagne/master/requirements.txt"
CONDA="https://github.com/jjhelmus/conda4aarch64/releases/download/1.0.0/c4aarch64_installer-1.0.0-Linux-aarch64.sh"
APT_DEPS=(ffmpeg wget)
LIBS_MODULES=(libblas-dev liblapack-dev llvm-9)

spinner() {
  pid=$! # Process Id of the previous running command
  
  spin='-\|/'
  
  i=0
  while kill -0 $pid 2>/dev/null
  do
  	  i=$(( (i+1) %4 ))
  	    printf "\r${spin:$i:1}"
  	      sleep .1
  done
}

license_agreement() {
echo "
	Before installation, please read and accept the license 
	agreement to install and use conda4aarch64.
	"

less -SFX <<EOF
Copyright (c) 2019 Jonathan J. Helmus
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

a. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

b. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the
distribution.

c. Neither the name of the author nor the names of contributors may
be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

EOF
while true;do
read -p "Do you accept the license agreement for conda4aarch64? " YN
  echo
  case $YN in
    yes|YES ) break;;
          * ) echo \
"You must accept the license agreement to use conda4aarch64.
If you really want to quit, use Ctrl+C.";;
  esac
done
}

install_deps() {
echo "Checking dependencies"
sudo apt update &> /dev/null
for i in "${LIBS_MODULES[@]}";do
  if [ $(apt list --installed 2>/dev/null | grep "$i" | wc -l) -le 0 ];then
    echo "Installing $i"
    sudo apt -y install ${i} &> /dev/null
  else
    echo "$i is installed!"
  fi
done

for i in "${APT_DEPS[@]}";do
  if ! which $i &>/dev/null ;then
    echo "Installing $i"
    sudo apt -y install ${i} &> /dev/null
  else
    echo "$i is installed!"
  fi
done

if [ -f /bin/llvm-config-9 ];then
  echo "Making symbolic link for llvm-config binary"
  sudo ln -sf /bin/llvm-config-9 /bin/llvm-config &> /dev/null
fi
}

install_birdnet() {
cd ~/BirdNET-system || exit 1
if [ ! -f "model/BirdNET_Soundscape_Model.pkl" ];then
  echo "Fetching the model"
  sh model/fetch_model.sh > /dev/null 
fi
if [ ! -f "./scripts/install_conda.sh" ];then
  echo "Fetching the conda4aarch64 installation script"
  wget -O ./scripts/install_conda.sh "${CONDA}" > /dev/null 
fi
echo "Installing conda4aarch64"
bash ./scripts/install_conda.sh > /dev/null<< EOF

yes

yes
EOF
echo "Initializing conda"
source ${HOME}/c4aarch64_installer/etc/profile.d/conda.sh
echo "Adding the conda-forge channel"
conda config --add channels conda-forge
echo "Initializing the birdnet virtual environment with
	- numba
	- numpy
	- scipy
	- future
	- theano
	- python=3.7"
conda create -y --name birdnet \
  numba numpy scipy future theano python=3.7 &> /dev/null
echo "Activating new environment"
conda activate birdnet > /dev/null 
echo "Upgrading pip, wheel, and setuptools"
pip install --upgrade pip wheel setuptools > /dev/null 
echo "Installing Librosa"
pip install librosa > /dev/null 
#echo "Installing Theano"
#pip install -r "$THEON" > /dev/null 
echo "Installing Lasagne"
pip install "$LASAG" > /dev/null 
}

echo "
	This script will do the following:
	#1: Present the licensing agreement for conda4aarch64
	#2: Install the following BirdNET system dependencies:
		- ffmpeg
		- libblas-dev
		- liblapack-dev
		- alsa-utils (for recording)
		- sshfs (to mount remote sound file directories)
	#3: Creates a conda virtual environment for BirdNET
	#4: Builds BirdNET in the 'birdnet' conda virtual environment
	#5: Copies the systemd .service and .mount files and enables those chosen
	#6: Adds cron environments and jobs chosen"

echo
read -sp "\
	If you DO NOT want to install BirdNET and the birdnet_analysis.service, 
	press Ctrl+C to cancel. If you DO wish to install BirdNET and the 
	birdnet_analysis.service, press ENTER to continue with the installation."


[ -d ${RECS_DIR} ] || mkdir -p ${RECS_DIR} &> /dev/null

license_agreement
install_deps
install_birdnet & spinner

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
