#!/bin/bash -e

# Comment code, because systemctl not installed in the docer image
# # Stop and disable apt-daily upgrade services;
# systemctl stop apt-daily.timer
# systemctl disable apt-daily.timer
# systemctl disable apt-daily.service
# systemctl stop apt-daily-upgrade.timer
# systemctl disable apt-daily-upgrade.timer
# systemctl disable apt-daily-upgrade.service

# Enable retry logic for apt up to 10 times
echo "APT::Acquire::Retries \"10\";" >/etc/apt/apt.conf.d/80-retries

# Configure apt to always assume Y
echo "APT::Get::Assume-Yes \"true\";" >/etc/apt/apt.conf.d/90assumeyes

# Uninstall unattended-upgrades
apt-get purge unattended-upgrades

# Need to limit arch for default apt repos due to
# https://github.com/actions/virtual-environments/issues/1961
sed -i'' -E 's/^deb http:\/\/(azure.archive|security).ubuntu.com/deb [arch=amd64,i386] http:\/\/\1.ubuntu.com/' /etc/apt/sources.list

echo 'APT sources limited to the actual architectures'
cat /etc/apt/sources.list

apt-get update

# Install jq
apt-get install jq

# Install apt-fast using quick-install.sh

apt_fast_installation() {
   if ! dpkg-query --show aria2 >/dev/null 2>&1; then
      apt-get update
      apt-get install -y aria2
   fi

   wget https://raw.githubusercontent.com/ilikenwf/apt-fast/master/apt-fast -O /usr/local/sbin/apt-fast
   chmod +x /usr/local/sbin/apt-fast
   if ! [[ -f /etc/apt-fast.conf ]]; then
      wget https://raw.githubusercontent.com/ilikenwf/apt-fast/master/apt-fast.conf -O /etc/apt-fast.conf
   fi
}

if [[ "$EUID" -eq 0 ]]; then
   apt_fast_installation
else
   type >/dev/null 2>&1 || {
      echo " not installed, change into root context" >&2
      exit 1
   }

   DECL="$(declare -f apt_fast_installation)"
   bash -c "$DECL; apt_fast_installation"
fi

# script not call because calling sudo command
# https://github.com/ilikenwf/apt-fast
# bash -c "$(curl -sL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"