#!/usr/bin/env bash

# IFNAME=eth0
# ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
# sed -e "s/^.*${HOSTNAME}.*/${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts

# # remove ubuntu-bionic entry
# sed -e '/^.*ubuntu-bionic.*/d' -i /etc/hosts

echo ""
echo "Write hosts file"
echo "#########################################################"

for server in $ALL_HOSTS
do
    host="${server%%:*}"
    ip="${server##*:}"

    echo "${ip} ${host}.${DOMAIN} ${host}" | tee -a /etc/hosts
done
