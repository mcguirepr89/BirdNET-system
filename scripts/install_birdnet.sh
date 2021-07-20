#!/usr/bin/env bash
# Install BirdNET script
my_dir=$(realpath $(dirname $0))
cd $my_dir || exit 1
#Install/Configure /etc/birdnet/birdnet.conf
sudo ./install_systemd.sh || exit 1
source /etc/birdnet/birdnet.conf

[ -d ${RECS_DIR} ] || mkdir -p ${RECS_DIR}

THEON="https://github.com/Lasagne/Lasagne/archive/master.zip"
LAS="https://raw.githubusercontent.com/Lasagne/Lasagne/master/requirements.txt"
APT_DEPS=(git ffmpeg sshfs)
LIBS_MODULES=(python3-pip python3-venv libblas-dev liblapack-dev)

echo "This script will do the following:
#1: Install the following BirdNET system dependencies:
	- ffmpeg
	- python3-venv
	- python3-pip
	- libblas-dev
	- liblapack-dev
	- sshfs (to mount remote sound file directories)
#2: Clones the BirdNET GitHub repository into your home directory:
	- "${HOME}"
#3: Creates a python virtual environment to install BirdNET site-packages:
	- "${VENV}"
#4: Builds BirdNET in the 'birdnet' virtual environment
#5: Copies the systemd .service and .mount files, only enabling the .mount 
	- /etc/systemd/system/birdnet_analysis.service
	- /etc/systemd/system/"${SYSTEMD_MOUNT}"
	- /etc/systemd/system/extraction.service
#6: Adds cron jobs:

  \"XDG_RUNTIME_DIR=/run/user/1000
    PATH=/usr/bin:/bin:/usr/local/bin
    * * * * * /usr/local/bin/birdnet_recording.sh >> /var/log/recording.log 2>&1
    */5 * * * * /usr/local/bin/species_notifier.sh &> /dev/null\""

echo
read -sp "                 Press Enter to continue or Crtl-C to quit"
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

cd ~/BirdNET-system || exit 1
python3 -m venv birdnet
source ./birdnet/bin/activate
pip3 install --upgrade pip wheel setuptools
pip3 install -r requirements.txt
sh model/fetch_model.sh
pip3 install -r "$LAS"
pip3 install "$THEON"

cd $my_dir || exit 1

sudo ln -sf ${my_dir}/* /usr/local/bin/
echo "BirdNet is finished installing!!"
echo
echo
read -n1 -p "Would you like to run the BirdNET service now?" YN
case $YN in
  [Yy] ) sudo systemctl start birdnet_analysis.service \
	   && journalctl -fu birdnet_analysis;;
     * ) echo "BirdNET is installed. To start the service, issue
	     sudo systemctl start birdnet_analysis
	     To monitor the service logs, issue
	     journalctl -fu birdnet_analysis"; exit;;
esac

