#!/usr/bin/env bash

echo ""
echo "Create kubernetes config dirs"
echo "#########################################################"

mkdir -p $CFG_DIR
mkdir -p $PKI_DIR

apt-get update -qq -y
apt-get install -qq -y bridge-utils
