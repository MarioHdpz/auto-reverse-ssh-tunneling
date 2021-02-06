#!/bin/bash

# TODO: Add cron to restart tunnel once a day
# 0 8 * * * /bin/systemctl restart autotunnel

# Use root user
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

while getopts ":k:p:h:u:" opt; do
  case $opt in
    k) key="$OPTARG"
    ;;
    p) port="$OPTARG"
    ;;
    h) host="$OPTARG"
    ;;
    u) user="$OPTARG"
    ;;
  esac
done

if [ -z "$key" ]
then
  echo >&2 "Must provide a key path (-k)!"; exit 1;
fi

if [ -z "$port" ]
then
  echo >&2 "Must provide a port (-p)!"; exit 1;
fi

if [ -z "$host" ]
then
  echo >&2 "Must provide a host (-h)!"; exit 1;
fi

if [ -z "$user" ]
then
  echo >&2 "Must provide a user (-u)!"; exit 1;
fi

# Check for internet connection
echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 -w 3 > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo >&2 "Must have internet connection!"; exit 1;
fi

apt-get update

# Install autossh if not installed
if [ $(dpkg-query -W -f='${Status}' autossh 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get install autossh -y;
fi

# Install autossh if not installed
if [ $(dpkg-query -W -f='${Status}' openssh-server 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get install openssh-server -y;
fi

# Enable ssh from localhost
systemctl start sshd
systemctl enable ssh.service

# Add used hosts to known hosts
if [ ! -e ~/.ssh/known_hosts ]; then
  touch ~/.ssh/known_hosts
fi
if ! cat ~/.ssh/known_hosts | grep -q localhost; then
  ssh-keyscan localhost >> ~/.ssh/known_hosts
fi
if ! cat ~/.ssh/known_hosts | grep -q $host; then
  ssh-keyscan $host >> ~/.ssh/known_hosts
fi

# Test ssh connections
ssh -i $key $user@$host exit
if [ $? -ne 0 ]; then
  echo >&2 "SSH connection failed!"; exit 1;
fi

conf_file="/etc/systemd/system/autotunnel.service"
if [ -e $conf_file ]; then
  rm $conf_file
  echo "Previous service conf file found, replacing..."
fi

echo -e "[Unit]" >> $conf_file
echo -e "Description=autossh daemon for ssh tunnel" >> $conf_file
echo -e "Wants=network-online.target" >> $conf_file
echo -e "After=network-online.target" >> $conf_file
echo -e "StartLimitIntervalSec=200" >> $conf_file
echo -e "StartLimitBurst=5" >> $conf_file
echo -e "\n[Service]" >> $conf_file
echo -e "ExecStart=/usr/bin/autossh -nNT -i ${key} ${user}@${host} -R ${port}:localhost:22" >> $conf_file
echo -e "Restart=always" >> $conf_file
echo -e "RestartSec=30" >> $conf_file
echo -e "RuntimeMaxSec=14400" >> $conf_file
echo -e "\n[Install]" >> $conf_file
echo -e "WantedBy=multi-user.target" >> $conf_file

systemctl daemon-reload
echo "Starting tunnel as a service..."
systemctl start autotunnel
sleep 5

tunnel_status="$(systemctl is-active autotunnel.service)"
if [ "${tunnel_status}" = "active" ]; then
    systemctl enable autotunnel.service
    echo "Tunnel succesfully opened on remote port ${port}"
else
  systemctl status autotunnel.service
fi
