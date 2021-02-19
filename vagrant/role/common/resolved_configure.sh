#!/usr/bin/env bash

echo ""
echo "set resolved dns address"
echo "#########################################################"
sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf
service systemd-resolved restart
