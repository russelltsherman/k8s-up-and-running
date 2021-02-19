#!/usr/bin/env bash

apt-get install -qq -y sshpass

CFG_HOST="k8s-m1"
SCP="scp -o StrictHostKeyChecking=no"

echo ""
echo "Copy Configuration from Controller:"
echo "#########################################################"

sshpass -p "${ROOTPASSWORD}" $SCP $CFG_HOST:$CFG_DIR/*.kubeconfig $CFG_DIR
sshpass -p "${ROOTPASSWORD}" $SCP $CFG_HOST:$CFG_DIR/*.yaml $CFG_DIR

# copy admin.kubeconfig to vagrant user space
mkdir -p /home/vagrant/.kube
cp $CFG_DIR/admin.kubeconfig /home/vagrant/.kube/config
chown -R vagrant /home/vagrant/.kube/
