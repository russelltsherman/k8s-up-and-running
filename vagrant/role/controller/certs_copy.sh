#!/usr/bin/env bash

apt-get install -qq -y sshpass

CERT_HOST="k8s-ca"
SCP="scp -o StrictHostKeyChecking=no"

echo ""
echo "Copy Certificates from CA server:"
echo "#########################################################"

sshpass -p "${ROOTPASSWORD}" $SCP $CERT_HOST:$PKI_DIR/*.crt $PKI_DIR
sshpass -p "${ROOTPASSWORD}" $SCP $CERT_HOST:$PKI_DIR/*.key $PKI_DIR
