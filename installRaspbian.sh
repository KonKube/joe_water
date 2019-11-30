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
  echo "Downloads $IMAGE image"
  curl -LO https://downloads.raspberrypi.org/raspbian_lite_latest
  unzip -o raspbian_lite_latest
  mv *.img raspbian.img
  rm -f raspbian_lite_latest
else
  echo "Image $IMAGE exists"
fi

if mountpoint -x $FILESYSTEM
then
  echo "Creating new filesystem on $FILESYSTEM with image $IMAGE"
  sudo dd bs=1M if=$IMAGE of=$FILESYSTEM status=progress
else
  echo "Filesystem $FILESYSTEM does not exists"
  exit 1
fi

BOOT_FS_PATH=/media/`whoami`/boot
ROOT_FS_PATH=/media/`whoami`/rootfs

echo "$BOOT_FS_PATH"
echo "$ROOT_FS_PATH"
