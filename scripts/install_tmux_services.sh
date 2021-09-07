#!/usr/bin/env bash
# Install tmux from source, then
# install multi-plexed gotty terminal
source /etc/birdnet/birdnet.conf
my_dir=$(realpath $(dirname $0))

# Install tmux from version control
install_tmux() {
  DEPENDS=( 
  automake
  autoconf
  libevent-2*
  libevent-dev 
  ncurses-bin
  ncurses-base
  ncurses-term
  libncurses-dev 
  build-essential 
  bison
  pkg-config 
  gcc
  )

  if which tmux &>/dev/null; then
    sudo apt -qqqy purge tmux &> /dev/null
    sudo rm -f $(which tmux)
  fi

  sudo apt update && sudo apt -y install "${DEPENDS[@]}"

  cd ${HOME} && git clone https://github.com/tmux/tmux.git
  cd tmux
  sh autogen.sh
  ./configure && make && sudo make install
  cd && rm -drf ./tmux
  sudo ln -sf "$(dirname ${myd_dir})/templates/tmux.conf" /etc/tmux.conf
}

install_web_terminal() {
  cat "$(dirname ${my_dir})/templates/birdterminal.service" \
    | sudo tee /etc/systemd/system/birdterminal.service
  HASHWORD="$(caddy hash-password -plaintext "${STREAM_PWD}")"
  cat << EOF | sudo tee -a /etc/caddy/Caddyfile
http://birdterminal.local {
  reverse_proxy localhost:9111
  basicauth {
    birdnet "${HASHWORD}"
  }
}
EOF
  sudo systemctl enable --now birdterminal.service
  sudo systemctl enable --now avahi-alias@birdterminal.local.service
  sudo systemctl restart caddy
}

