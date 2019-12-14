#!/bin/bash

set -e

MAIL_RECIPIENT=$1

if [[ ! -f ~/initial.lock ]]
then
  # initialize locales
  echo "initialize locales"
  export LANGUAGE=en_GB.UTF-8
  export LANG=en_GB.UTF-8
  export LC_ALL=en_GB.UTF-8
  sudo /usr/sbin/locale-gen en_GB.UTF-8

  # initial update and upgrade on first boot
  echo "apt-get update"
  sudo apt-get update
  ### raspbian upgrade Bug https://www.raspberrypi.org/forums/viewtopic.php?t=258330&p=1575034
  #echo "apt-get upgrade"
  #sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

  # install mandatory resources
  echo "install libsqlite3-dev"
  sudo apt-get -y install \
    libsqlite3-dev

  if [[ -f ~/.msmtprc ]] && [[ -f ~/mail.sh ]]
  then
    # install email resources
    echo "install msmtp and mailutils"
    sudo apt-get -y install \
      msmtp \
      msmtp-mta \
      mailutils
  fi

  # download and install latest wiringPi
  echo "install wiringPi"
  curl -LO https://project-downloads.drogon.net/wiringpi-latest.deb
  sudo dpkg -i wiringpi-latest.deb

  # download and install latest sprinklers_pi version
  echo "install sprinklers_pi"
  curl -L -o sprinklers_pi.tar.gz https://github.com/rszimm/sprinklers_pi/archive/v1.5.3.tar.gz
  tar xzfv sprinklers_pi.tar.gz
  mv sprinklers_pi-* sprinklers_pi
  cd sprinklers_pi

  # enabled GreenIQ in
  echo "activate GREENIQ configuration of sprinklers_pi"
  sed -i 's/^\/\/#define GREENIQ/#define GREENIQ/g' /home/pi/sprinklers_pi/config.h

  make
  sudo make install

  # create initial.lock
  echo "create initial.lock"
  ~/mail.sh $MAIL_RECIPIENT InitialSetup-$HOSTNAME-Sucessful"
  touch ~/initial.lock
  sudo reboot now
fi
