#!/usr/bin/env bash

apt-get install -qq -y sshpass

CERT_HOST="k8s-ca"
KCFG_HOST="k8s-m1"
SCP="scp -o StrictHostKeyChecking=no"

echo ""
echo "Copy Certificates from CA server:"
echo "#########################################################"

mkdir -p ${PKI_DIR}

sshpass -p "${ROOTPASSWORD}" $SCP $CERT_HOST:${PKI_DIR}/ca.crt ${PKI_DIR}/
sshpass -p "${ROOTPASSWORD}" $SCP $CERT_HOST:${PKI_DIR}/"$(hostname)".crt ${PKI_DIR}/
sshpass -p "${ROOTPASSWORD}" $SCP $CERT_HOST:${PKI_DIR}/"$(hostname)".key ${PKI_DIR}/


echo ""
echo "Copy Configuration from Controller:"
echo "#########################################################"

sshpass -p "${ROOTPASSWORD}" $SCP $KCFG_HOST:${CFG_DIR}/kube-proxy.kubeconfig ${CFG_DIR}/
sshpass -p "${ROOTPASSWORD}" $SCP $KCFG_HOST:${CFG_DIR}/"$(hostname)".kubeconfig ${CFG_DIR}/
