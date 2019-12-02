#!/bin/bash

set -e

if [[ ! -f ~/initial.lock ]]
then
  # initialize locales
  sudo /usr/sbin/locale-gen en_US.UTF-8

  # initial update and upgrade on first boot
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

  # install mandatory resources
  sudo apt-get -y install \
    wiringpi \
    libsqlite3-dev \
    build-essential

  if [[ -f ~/ssmtp.conf ]] && [[ -f ~/mail.sh ]]
  then
    # install email resources
    sudo apt-get -y install \
      ssmtp \
      mailutils

    sudo cp  ~/ssmtp.conf /etc/ssmtp/ssmtp.conf
    echo "pi:joewater.konkube@gmail.com:smtp.gmail.com:587" | sudo tee -a /etc/ssmtp/revaliases
  fi

  # download and install latest sprinklers_pi version
  curl -L -o sprinklers_pi.tar.gz https://github.com/rszimm/sprinklers_pi/archive/v1.5.3.tar.gz
  tar xzfv sprinklers_pi.tar.gz
  mv sprinklers_pi-* sprinklers_pi
  cd sprinklers_pi
  make
  sudo make install

  # enabled GreenIQ in
  sed -i 's/^\/\/#define GREENIQ/#define GREENIQ/g' /home/pi/sprinklers_pi/config.h

  # create initial.lock
  touch ~/initial.lock
  sudo reboot now
fi
