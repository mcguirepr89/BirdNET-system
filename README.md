# BirdNET-system for arm64/aarch64 (Raspberry Pi 4)
### Built on https://github.com/kahst/BirdNET -- checkout the Wiki at [BirdNETWiki.pmcgui.xyz](https://birdnetwiki.pmcgui.xyz)

This project offers an installation script for BirdNET as a systemd service on arm64 (aarch64) Debian-based operating systems, namely RaspiOS. The installation script offers to walk the user through setting up the '*birdnet.conf*' main configuration file interactively, or can read from an existing '*birdnet.conf*'. A variety of configurations can be attained through this installation script.

BirdNET-system can be configured with the following optional services:
- A 24/7 recording script that can be easily configured to use any available sound card
- An extraction service that extracts the audio selections identified by BirdNET by date and species
- A Caddy instance that serves the extracted files and live audio stream (icecast2) (requires dsnoop capable mic)
- A species list updating and notification script supporting mobile notifications via Pushed.co (sorry, Android users, Pushed.co doesn't seem to work for you)
- NoMachine remote desktop software (for personal use only)

An installation one-liner is available [HERE](https://birdnetwiki.pmcgui.xyz/wiki/Birder%27s_Guide_to_BirdNET-system#Install_BirdNET-system). 
- Prerequisites:
  - An updated RaspiOS for AArch64 that has locale, WiFi, time-zone, and pi user password set. A guide is available [here](https://birdnetwiki.pmcgui.xyz/wiki/Birder%27s_Guide_to_BirdNET-system#Install_the_base_operating_system_.28OS.29)
  - A USB microphone (dsnoop capable to enable live audio stream).


## What the installation does
1. Looks for a *'birdnet.conf'* file in the *BirdNET-system* main directory
1. If a *'birdnet.conf'* file exists and is filled out properly, the installation is nearly
   non-interactive and builds the system based off of the services configured in the *'birdnet.conf'* file
1. If the installer cannot find a *'birdnet.conf'* file,  the installation is interactive and will
   walk the user through creating the '*birdnet.conf'* file interactively.
1. Installs the following system dependencies:
	- ffmpeg
	- libblas-dev
	- liblapack-dev
	- caddy (for web access to extractions)
	- icecast2 (live audio stream)
	- alsa-utils (for recording)
	- sshfs (to mount remote sound file directories)
1. Installs BirdNET-system scripts in */usr/local/bin*
1. Installs all selected services based on '*birdnet.conf*'
1. Installs *miniforge* for the aarch64 architecture using the current release from https://github.com/conda-forge/miniforge
1. Builds BirdNET in miniforge's *'birdnet'* virtual environment
1. Enables (but does not start) the services

## What you should know before beginning the installation
1. The latitude and longitude where the bird recordings take place. Google maps is an easy way to find these (right-clicking the location).
1. The directory where the recordings should be found on your local computer. BirdNET-system supports setting up a systemd.mount for automounting remote directories. So for instance, if the actual recordings live on RemoteHost's `/home/user/recordings` directory, but you would like them to be found on your device at `/home/me/BirdNET-recordings`, then `/home/me/BirdNET-recordings` will be your answer to that question.
1. If mounting the recordings directory from a remote host, you need to know the *remote* username to connect to via SSH, as well as the absolute path of the recordings on the remote host.
1. In order for the live audio stream to work at the same time as the birdnet_recording.service, the microphone needs to be dsnoop capable. If you are wondering whether your mic supports creating the dsnoop device, you can use `aplay -L | awk -F, '/dsn/ {print $1}' | grep -ve 'vc4' -e 'Head' -e 'PCH' | uniq` to check. (No output means your microphone does not support creating a dsnoop device and therefore cannot also provide an audio stream while recording. The birdnet_recording.service, however, should not be affected by this.)
1. If you are using a special microphone or have multiple sound cards and would like to specify which to use for recording, you can edit the `/etc/birdnet/birdnet.conf` file when the installation is complete and set ${REC_CARD} to the sound card of your choice. Copy your desired sound card line from the output of ` aplay -L | awk -F, '/^hw:/ { print $1 }'`. 
1. If you would like to take advantage of Caddy's automatic handling of SSL certificates to be able to host a public website where your friends can hear your bird sounds, forward ports 80 and 443 to the host you want to serve the files. You may also want to purchase a domain name.
   - *Note: If you're just keeping this on your local network, be sure to set your extraction URL to something 'http://', [on RaspiOS, I recommend http://raspberrypi.local] to disable Caddy's automatic HTTPS. Alternatively, you may edit the `/etc/caddy/Caddyfile` after installation and add the `tls internal` directive to the site block to have Caddy issue a self-signed certificate for an HTTPS connection.*
1. If you would like to take advantage of BirdNET-system's ability to send New Species mobile notifications, you can easily setup a Pushed.co notification app (see the #TODOs at the bottom for more info). After setting up your application, make note of your App Key and App Secret -- you will need these to enable mobile notifications for new species. 
   - Note for Android users: it seems that the Pushed.co Mobile App does not work for Android devices, which is a huge bummer. If anyone knows of an Android alternative, or if anyone might be able to come up with a home-spun notification system, please let me know.

## How to install
#### Option 1 -- Pre-fill birdnet.conf
1. In the terminal run `cd ~ && git clone https://github.com/mcguirepr89/BirdNET-system.git`
1. **Switch to this branch, BirdNET-system-for-raspi4** `cd ~/BirdNET-system && git checkout BirdNET-system-for-raspi4`
1. You can copy the included *'birdnet.conf-defaults'* template to create and configure the BirdNET-system
   to your needs before running the installer. Issue `cp ${HOME}/BirdNET-system/birdnet.conf-defaults ${HOME}/BirdNET-system/birdnet.conf`.
   Edit the new *'birdnet.conf'* file to suit your needs and save it.
   If you choose this method, the installation will be (nearly) non-interactive.
1. Run `~/BirdNET-system/scripts/install_birdnet.sh`
#### Option 2 -- Interactive Installation
1. In the terminal run `cd ~ && git clone https://github.com/mcguirepr89/BirdNET-system.git`
1. **Switch to this branch, BirdNET-system-for-raspi4** `cd ~/BirdNET-system && git checkout BirdNET-system-for-raspi4`
1. Run `~/BirdNET-system/scripts/install_birdnet.sh`
1. Follow the installation prompts to configure the BirdNET-system to your needs.
- Note: The installation should be run as a regular user. If run on an OS other than RaspiOS, be sure the regular user is in the sudoers file or the sudo group.

## Access your BirdNET-system
If you configured BirdNET-system with the Caddy webserver, you can access the extractions locally at

- http://birdnetsystem.local

You can also view the log output for the <code>birdnet_analysis.service</code> and <code>extraction.service</code> at

- http://birdlog.local
- http://extractionlog.local

and the BirdNET-system Statistics Report at
- http://birdstats.local

If you opt to also install NoMachine alongside the BirdNET-system, you can also access BirdNET-system
remotely following the address information that can be found on the NoMachine's server information page.

## Examples
These are examples of my personal instance of the BirdNET-system on a Raspberry Pi 4B.
 - https://birdsounds.pmcgui.xyz  -- My BirdNET-system Extractions page
 - https://birdlog.pmcgui.xyz  --  My 'birdlog' birdnet_analysis.service log
 - https://extraction.pmcgui.xyz  --  My 'extractionlog' extraction.service log
 - https://birdstats.pmcgui.xyz  -- My 'birdstats' BirdNET-system Report

## How to reconfigure the system
At any time, you can completely reconfigure the system to select or remove features. To reconfigure the system, simply run the included "reconfigure_birdnet.sh" script (as the regular user) and follow the prompts to create a new birdnet.conf file and install new services: `~/BirdNET-system/scripts/reconfigure_birdnet.sh`

## How to uninstall BirdNET-system
To remove BirdNET-system, run the included '*uninstall.sh*' script as the regular user.
1. Issue `/usr/local/bin/uninstall.sh && cd ~ && rm -drf BirdNET-system`

### TODO & Notes:
1. I ought to add the steps to setup a Pushed.co application for the mobile notifications feature. Here is a link for now https://pushed.co/quick-start-guide
