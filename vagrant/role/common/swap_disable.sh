#!/usr/bin/env bash


echo ""
echo "Disable swap"
echo "#########################################################"
sed -i '/swap/d' /etc/fstab
swapoff -a
