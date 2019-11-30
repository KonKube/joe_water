#!/bin/bash

# ./installRaspbian.sh joewater /dev/sdb Europe/Berlin

set -e
set -o pipefail

HOSTNAME=$1
FILESYSTEM=$2
TIMEZONE=$3

IMAGE=raspbian.img

if [[ ! -f "$IMAGE" ]]
then
  echo "downloads $IMAGE image"
  curl -LO https://downloads.raspberrypi.org/raspbian_lite_latest
  unzip -o raspbian_lite_latest
  mv *.img raspbian.img
  rm -f raspbian_lite_latest
else
  echo "image $IMAGE exists"
fi

if mountpoint -x $FILESYSTEM > /dev/null 2>&1
then
  echo "creating filesystem on $FILESYSTEM with image $IMAGE"
  sudo dd bs=1M if=$IMAGE of=$FILESYSTEM status=progress
  if [ $? -eq 0 ]
  then
    echo "creating filesystem from image $IMAGE was successful"
  else
    echo "creating filesystem from image $IMAGE failed"
    exit 1
  fi
else
  echo "filesystem $FILESYSTEM does not exists"
  exit 1
fi

if [[ -d /media/`whoami`/rootfs ]]
then
  ROOT_FS_PATH=/media/`whoami`/rootfs
  echo "root filesystem path $ROOT_FS_PATH created"
else
  echo "root filesystem path from created filesystem does not exists"
  exit 1
fi

if [[ -d /media/`whoami`/boot ]]
then
  BOOT_FS_PATH=/media/`whoami`/boot
  echo "boot filesystem path $BOOT_FS_PATH created"
else
  echo "boot filesystem path from created filesystem does not exists"
  exit 1
fi

if [[ -f "wpa_supplicant.conf" ]]
then
  echo "adding wpa_supplicant.conf to $ROOT_FS_PATH/etc/wpa_supplicant/wpa_supplicant.conf"
  cat wpa_supplicant.conf | sudo tee $ROOT_FS_PATH/etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
fi

echo "sets local time to $TIMEZONE"
sudo rm $ROOT_FS_PATH/etc/localtime
sudo cp $ROOT_FS_PATH/usr/share/zoneinfo/$TIMEZONE $ROOT_FS_PATH/etc/localtime

if [[ -f ~/.ssh/id_rsa.pub ]]
then
  echo "adding ~/.ssh/id_rsa.pub and deactivating password authentication"
  sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/g' $ROOT_FS_PATH/etc/ssh/sshd_config
  sudo sed -i 's/^UsePAM yes/UsePAM no/g' $ROOT_FS_PATH/etc/ssh/sshd_config
  if [[ ! -d "$ROOT_FS_PATH/home/pi/.ssh" ]]
  then
    echo "creating $ROOT_FS_PATH/home/pi/.ssh directory"
    sudo mkdir $ROOT_FS_PATH/home/pi/.ssh
  fi
  cat ~/.ssh/id_rsa.pub | sudo tee $ROOT_FS_PATH/home/pi/.ssh/authorized_keys > /dev/null
  sudo chown 1000:1000 $ROOT_FS_PATH/home/pi/.ssh/authorized_keys
fi

if [[ -f $ROOT_FS_PATH/etc/sudoers ]]
then
  echo "giving sudo privileges to user pi"
  echo "pi ALL=(ALL) NOPASSWD:ALL" | sudo tee -a $ROOT_FS_PATH/etc/sudoers > /dev/null
fi

if [[ ! -f "$BOOT_FS_PATH/ssh" ]]
then
  echo "enabling ssh login"
  touch $BOOT_FS_PATH/ssh
fi
