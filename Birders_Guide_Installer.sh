#!/usr/bin/env bash
sudo apt update && sudo apt install -y git

cd ~ || exit 1

git clone https://github.com/mcguirepr89/BirdNET-system.git
cd BirdNET-system
echo "Finished"
echo "Press Enter to close this window"
read
