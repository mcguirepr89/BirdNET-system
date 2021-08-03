#!/usr/bin/env bash
# Testing the installation script via GitHub Actions
./scripts/install_birdnet.sh <<"EOF"
yrunner
/home/runner/BirdSongs
-80.754
35.678
yyyhttp://localhost
n
n
EOF
./birdnet/bin/python3 analyze.py --i example/Soundscape_1.wav --lat 42.479 --lon -76.451
