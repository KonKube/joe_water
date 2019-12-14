#!/bin/bash
# ./installRaspbian.sh joewater /dev/sdb Europe/Berlin sender@gmail recipient@gmail

set -e
set -o pipefail

HOSTNAME=$1
FILESYSTEM=$2
TIMEZONE=$3
MAIL_SENDER=$4
MAIL_RECIPIENT=$5

IMAGE=raspbian.img
ROOT_FS_PATH=/media/`whoami`/rootfs
BOOT_FS_PATH=/media/`whoami`/boot

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

if mountpoint -x $FILESYSTEM\2
then
  if mountpoint -q $ROOT_FS_PATH
  then
    echo "rootfs filesystem path $ROOT_FS_PATH is mounted"
    echo "unmount $ROOT_FS_PATH"
    sudo umount $ROOT_FS_PATH
  fi
  echo "fix rootfs $ROOT_FS_PATH with fsck"
  sudo fsck -y $FILESYSTEM\2
  echo "successful fixed $ROOT_FS_PATH"
fi

if [[ -d $ROOT_FS_PATH ]]
then
  echo "rootfs mount path $ROOT_FS_PATH exists"
  if mountpoint -q $ROOT_FS_PATH
  then
    echo "rootfs mount path $ROOT_FS_PATH is mounted"
  else
    echo "mount filesystem to $ROOT_FS_PATH"
    sudo mount $FILESYSTEM\2 $ROOT_FS_PATH
  fi
else
  echo "rootfs mount path $ROOT_FS_PATH does not exists"
  echo "creating missing path $ROOT_FS_PATH"
  sudo mkdir $ROOT_FS_PATH
  echo "mount filesystem to $ROOT_FS_PATH"
  sudo mount $FILESYSTEM\2 $ROOT_FS_PATH
fi

if mountpoint -x $FILESYSTEM\1
then
  if mountpoint -q $BOOT_FS_PATH
  then
    echo "boot filesystem path $BOOT_FS_PATH is mounted"
    echo "unmount $BOOT_FS_PATH"
    sudo umount $BOOT_FS_PATH
  fi
  echo "fix boot $BOOT_FS_PATH with fsck"
  sudo fsck -y $FILESYSTEM\1
  echo "successful fixed $BOOT_FS_PATH"
fi

if [[ -d $BOOT_FS_PATH ]]
then
  echo "boot mount path $BOOT_FS_PATH exists"
  if mountpoint -q $BOOT_FS_PATH
  then
    echo "boot mount path $BOOT_FS_PATH is mounted"
  else
    echo "mount filesystem to $BOOT_FS_PATH"
    sudo mount $FILESYSTEM\1 $BOOT_FS_PATH
  fi
else
  echo "boot mount path $BOOT_FS_PATH does not exists"
  echo "creating missing path $BOOT_FS_PATH"
  sudo mkdir $BOOT_FS_PATH
  echo "mount filesystem to $BOOT_FS_PATH"
  sudo mount $FILESYSTEM\1 $BOOT_FS_PATH
fi

if [[ -d $ROOT_FS_PATH ]]
then
  if [[ -f ./wpa_supplicant.conf ]]
  then
    echo "adding wpa_supplicant.conf to /etc/wpa_supplicant/wpa_supplicant.conf"
    cat wpa_supplicant.conf | sudo tee -a $ROOT_FS_PATH/etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
  fi

  if [[ ! -z "$HOSTNAME" ]]
  then
    echo "set hostname to $HOSTNAME"
    echo $HOSTNAME | sudo tee $ROOT_FS_PATH/etc/hostname > /dev/null
  else
    echo "could not set hostname to $HOSTNAME"
    exit 1
  fi

  if [[ ! -z "$TIMEZONE" ]]
  then
    echo "set local time to $TIMEZONE"
    sudo rm $ROOT_FS_PATH/etc/localtime
    sudo cp $ROOT_FS_PATH/usr/share/zoneinfo/$TIMEZONE $ROOT_FS_PATH/etc/localtime
  else
    echo "could not set local time to $TIMEZONE"
    exit 1
  fi

  if [[ -f ~/.ssh/id_rsa.pub ]]
  then
    echo "adding ~/.ssh/id_rsa.pub and deactivating password authentication"
    sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/g' $ROOT_FS_PATH/etc/ssh/sshd_config
    sudo sed -i 's/^UsePAM yes/UsePAM no/g' $ROOT_FS_PATH/etc/ssh/sshd_config
    if [[ ! -d "$ROOT_FS_PATH/home/pi/.ssh" ]]
    then
      echo "creating /home/pi/.ssh directory"
      sudo mkdir $ROOT_FS_PATH/home/pi/.ssh
      sudo chown 1000:1000 $ROOT_FS_PATH/home/pi/.ssh
    fi
    sudo cp -a ~/.ssh/id_rsa.pub $ROOT_FS_PATH/home/pi/.ssh/authorized_keys
  fi

  if [[ -f $ROOT_FS_PATH/etc/sudoers ]]
  then
    echo "giving sudo privileges to user pi"
    echo "pi ALL=(ALL) NOPASSWD:ALL" | sudo tee -a $ROOT_FS_PATH/etc/sudoers > /dev/null
  fi

  if [[ -f ./installApplication.sh ]]
  then
    echo "adding installApplication.sh to /home/pi/installApplication.sh"
    cp ./installApplication.sh $ROOT_FS_PATH/home/pi/installApplication.sh
    sudo chmod 755 $ROOT_FS_PATH/home/pi/installApplication.sh
    if [[ -f ./.msmtprc && -f ./mail.sh && ! -z "$MAIL_RECIPIENT" ]]
    then
      echo "@reboot ~/installApplication.sh $MAIL_RECIPIENT > ~/installApplication.log 2>&1" | sudo tee -a $ROOT_FS_PATH/var/spool/cron/crontabs/pi
    else
      echo "@reboot ~/installApplication.sh > ~/installApplication.log 2>&1" | sudo tee -a $ROOT_FS_PATH/var/spool/cron/crontabs/pi
    fi
    sudo chown 1000:crontab $ROOT_FS_PATH/var/spool/cron/crontabs/pi
    sudo chmod 600 $ROOT_FS_PATH/var/spool/cron/crontabs/pi
  fi

  if [[ -f ./.msmtprc && -f ./mail.sh && ! -z "$MAIL_RECIPIENT" ]]
  then
    echo "adding .msmtprc and mail.sh to /home/pi/"
    cp ./.msmtprc $ROOT_FS_PATH/home/pi/.msmtprc
    sudo chmod 600 $ROOT_FS_PATH/home/pi/.msmtprc
    cp ./mail.sh $ROOT_FS_PATH/home/pi/mail.sh
    sudo chmod 755 $ROOT_FS_PATH/home/pi/mail.sh

    echo "set up /etc/aliases and /etc/mail.rc"
    echo "root: $MAIL_SENDER" | sudo tee -a $ROOT_FS_PATH/etc/aliases
    echo "default: $MAIL_SENDER" | sudo tee -a $ROOT_FS_PATH/etc/aliases
    echo 'set sendmail="/usr/bin/msmtp -t"' | sudo tee -a $ROOT_FS_PATH/etc/mail.rc

    echo "adding mail notification for reboots and daily heartbeats"
    echo "@reboot sleep 30 && ~/mail.sh $MAIL_RECIPIENT REBOOT-$HOSTNAME"  | sudo tee -a $ROOT_FS_PATH/var/spool/cron/crontabs/pi
    echo "0 16 * * * ~/mail.sh $MAIL_RECIPIENT HEARTBEAT-$HOSTNAME"  | sudo tee -a $ROOT_FS_PATH/var/spool/cron/crontabs/pi
  fi
else
  echo "could not find $ROOT_FS_PATH"
fi

if [[ -d $BOOT_FS_PATH ]]
then
  if [[ ! -f "$BOOT_FS_PATH/ssh" ]]
  then
    echo "enabling ssh login"
    sudo touch $BOOT_FS_PATH/ssh
  fi
else
  echo "could not find $BOOT_FS_PATH"
fi

sleep 10
echo "removes mounts"
sudo umount $ROOT_FS_PATH
sudo umount $BOOT_FS_PATH
sleep 10
echo "removes mountpoints"
sudo rm -rf $ROOT_FS_PATH
sudo rm -rf $BOOT_FS_PATH
echo "finished!"
