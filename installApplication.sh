#!/bin/bash

sudo apt-get update
sudo apt-get upgrade

sudo apt-get install \
  curl \
  wiringpi \
  libsqlite3-dev \
  build-essential

curl -L -o sprinklers_pi.tar.gz https://github.com/rszimm/sprinklers_pi/archive/v1.5.3.tar.gz
mv sprinklers_pi-* sprinklers_pi

make
sudo make install


sudo reboot now
