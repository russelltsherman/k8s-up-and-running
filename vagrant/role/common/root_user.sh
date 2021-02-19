#!/usr/bin/env bash

echo ""
echo "Set Root password"
echo "#########################################################"
echo -e "${ROOTPASSWORD}\n${ROOTPASSWORD}" | passwd root


echo ""
echo "Enable ssh password authentication"
echo "#########################################################"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd
