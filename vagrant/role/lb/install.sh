#!/usr/bin/env bash

# In this script we will provision an external load balancer to front the Kubernetes API Servers. 
# The `k8s-the-hard-way` static IP address will be attached to the resulting load balancer.

echo ""
echo "Install haproxy"
echo "#########################################################"

apt-get update -qq -y
apt-get install -qq -y haproxy
