#!/bin/bash

set -e

if [[ ! -f ~/initial.lock ]]
  # initialize locales
  sudo /usr/sbin/locale-gen

  # initial update and upgrade on first boot
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

  # install mandatory resources
  sudo apt-get -y install \
    curl \
    wiringpi \
    libsqlite3-dev \
    build-essential

  # download and install latest sprinklers_pi version
  curl -L -o sprinklers_pi.tar.gz https://github.com/rszimm/sprinklers_pi/archive/v1.5.3.tar.gz
  mv sprinklers_pi-* sprinklers_pi
  cd sprinklers_pi
  make
  sudo make install

  touch ~/initial.lock
  sudo reboot now
fi
