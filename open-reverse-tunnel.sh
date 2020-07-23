#!/bin/bash
set -e

# Use root user
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Install autossh if not installed
if [ $(dpkg-query -W -f='${Status}' autossh 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get install autossh -y;
fi
