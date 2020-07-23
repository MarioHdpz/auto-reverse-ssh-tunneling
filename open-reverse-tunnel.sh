#!/bin/bash

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
ssh-keyscan localhost >> ~/.ssh/known_hosts
ssh-keyscan $host >> ~/.ssh/known_hosts

# Test ssh connections
ssh -i $key $user@$host exit
if [ $? -ne 0 ]; then
  echo >&2 "SSH connection failed!"; exit 1;
fi

# Start reverse tunnel
autossh -f -nNT -i $key -N $user@$host -R $port:localhost:22

echo "Tunnel opened on remote port ${port}"
