# BirdNET-system - built on https://github.com/kahst/BirdNET
This project offers a Debian installation script for BirdNET as a systemd service. The installation script offers to walk the user through setting up the '*birdnet.conf*' main configuration file interactively. A variety of configurations can be attained through this installation script.

BirdNET-system can be configured with the following optional services:
- A recording script that will automate recording the two hours following sunrise and the two hours preceeding sunset for optimal bird listening.
- An extraction service that extracts the audio selections idetified by BirdNET by date and species.
- A Caddy instance that serves the extracted files via a configurable ${EXTRACTIONS_URL}.
- A species list updating and notification script supporting mobile notifications via Pushed.co

Currently, there are three types of configurations that I've tried and that have worked for me. They include the following:
1. All-in-One
   - This performs the following:
     - Recording
     - BirdNET Analysis
     - Extraction of identified BirdNET selections
     - Hosting extracted selections via Caddy at configurable ${EXTRACTIONS_URL}
1. Recorder/Analyzer
   - These work together accordingly:
     - Recorder
       - Recording
       - Extraction & Hosting (optional)
     - Analyzer
       - BirdNET Analysis
       - Extraction & Hosting (optional)
1. Minimal
   - Just a recorder
   - Just a BirdNET analysis service

## What the installation does
1. Copies all scripts to */usr/local/bin*.
1. Walks through settings in the *'birdnet.conf'* file.
1. Installs the following system dependencies:
	- ffmpeg
	- python3-venv
	- python3-pip
	- libblas-dev
	- liblapack-dev
	- caddy (for web access to extractions)
	- alsa-utils (for recording)
	- sshfs (to mount remote sound file directories)
1. Creates a python virtual environment to install BirdNET site-packages.
1. Builds BirdNET in the *'birdnet'* virtual environment.
1. Creates and copies the appropriate systemd *.service* and/or *.mount* files
1. Installs any selected '*.cron*' jobs.

## What you should know before beginning the installation
1. Your username that you will work as your ${BIRDNET_USER}. To get this, go to your terminal and issue `whoami`.
1. The directory where the recordings should be found on your local computer. BirdNET-system supports setting up a systemd.mount for automounting remote directories. So for instance, if the actual recordings live on RemoteHost's `/home/user/recordings` directory, but you would like them to be found on your device at `/home/me/BirdNET-recordings`, then `/home/me/BirdNET-recordings` will be your answer to installation question 2.
1. The latitude and longitude where the bird recordings take place. Google maps is an easy way to find these (right-clicking the location).
1. If you are using a special microphone or have multiple sound cards and would like to specify which to use for recording, you can edit the `/etc/birdnet/birdnet.conf` file when the installation is complete and set ${REC_CARD} to the sound card of your choice. Copy your desired sound card line from the output of ` aplay -L | grep -e '^hw:CARD' | cut -d',' -f1`.
. 


## How to install
1. In the terminal run `cd ~ && git clone https://github.com/mcguirepr89/BirdNET-system.git`
1. Run `~/BirdNET-system/scripts/install_birdnet.sh`
1. Follow the installation prompt to configure your BirdNET-system to your needs.
- Note: The installation should be run as a regular user, but will require super user privileges, i.e., will ask you for your super user password.

## How to reconfigure your setup
At any time, you can reconfigure the settings you opted for during installation by running the '*reconfigure_birdnet.sh*' script with super user privileges.
Just issue `sudo reconfigure_birdnet.sh` and that ought to do the trick.

## How to uninstall BirdNET-system
To remove BirdNET and BirdNET-system, run the included '*uninstall.sh*' script as the ${BIRDNET_USER}.
1. Change to the BirdNET-system installation directory and issue `./scripts/uninstall.sh`.
1. Then `cd ~ && rm -drf BirdNET-system`

### TODO:
1. Currently, one needs to set up the ssh-keys between the recorder and analyzer manually if configured to use the SSHFS systemd.mount. I will be adding the ssh-key exchange to the installation script soon.
1. I ought to add the steps to setup a Pushed.co application for the mobile notifications feature. Here is a link for now https://about.pushed.co/docs/productguides#developers-quick-start
1. It's kind of cool to reverse-proxy a gotty web terminal of the birdnet_analysis.service log output (`journalctl -fu birdnet_analysis`), so I may add that.
