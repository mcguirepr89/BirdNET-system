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
