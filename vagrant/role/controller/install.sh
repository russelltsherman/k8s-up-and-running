#!/usr/bin/env bash

# In this script we will bootstrap the Kubernetes control plane across 2 compute instances and configure it for high availability. 
# You will also create an external load balancer that exposes the Kubernetes API Servers to remote clients. 
# The following components will be installed on each node: Kubernetes API Server, Scheduler, and Controller Manager.

# This script must be run on each controller instance: `k8s-m1`, and `k8s-m2`.

# Reference : 
#     https://kubernetes.io/docs/setup/release/#server-binaries

echo ""
echo "Download the official Kubernetes release binaries:"
echo "#########################################################"

curl -L -o /usr/local/bin/kube-apiserver --silent --show-error \
https://storage.googleapis.com/kubernetes-release/release/v1.18.4/bin/linux/amd64/kube-apiserver
chmod 755 /usr/local/bin/kube-apiserver

curl -L -o /usr/local/bin/kube-controller-manager --silent --show-error \
https://storage.googleapis.com/kubernetes-release/release/v1.18.4/bin/linux/amd64/kube-controller-manager
chmod 755 /usr/local/bin/kube-controller-manager

curl -L -o /usr/local/bin/kube-scheduler --silent --show-error \
https://storage.googleapis.com/kubernetes-release/release/v1.18.4/bin/linux/amd64/kube-scheduler
chmod 755 /usr/local/bin/kube-scheduler

curl -L -o /usr/local/bin/kubectl --silent --show-error \
https://storage.googleapis.com/kubernetes-release/release/v1.18.4/bin/linux/amd64/kubectl
chmod 755 /usr/local/bin/kubectl


echo ""
echo "Download the official etcd release binaries"
echo "#########################################################"

wget -q --https-only --timestamping \
  https://github.com/coreos/etcd/releases/download/v3.4.9/etcd-v3.4.9-linux-amd64.tar.gz

tar -xf etcd-v3.4.9-linux-amd64.tar.gz
mv etcd-v3.4.9-linux-amd64/etcd* /usr/local/bin/
rm -rf etcd-v3.4.9-linux-amd64*


echo ""
echo "Download the official calico release binaries"
echo "#########################################################"

curl -L -o /usr/local/bin/calicoctl --silent --show-error \
https://github.com/projectcalico/calicoctl/releases/download/v3.15.0/calicoctl
chmod 755 /usr/local/bin/calicoctl

echo "export CALICO_DATASTORE_TYPE=kubernetes" >> /home/vagrant/.bashrc
echo "export CALICO_KUBECONFIG=~/.kube/config" >> /home/vagrant/.bashrc
echo "export CALICO_ETCD_ENDPOINTS=https://192.168.5.21:2379,https://192.168.5.21:2379" >> /home/vagrant/.bashrc
