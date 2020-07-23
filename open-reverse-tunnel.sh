#!/bin/bash

# Use root user
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

while getopts ":k:p:" opt; do
  case $opt in
    k) key="$OPTARG"
    ;;
    p) port="$OPTARG"
    ;;
  esac
done

if [ -z "$key" ]
then
  echo >&2 "Must provide a key path!"; exit 1;
fi

if [ -z "$port" ]
then
  echo >&2 "Must provide a port!"; exit 1;
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

