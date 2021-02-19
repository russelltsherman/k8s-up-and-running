#!/usr/bin/env bash

echo ""
echo "Create haproxy configuration"
echo "#########################################################"

K8S_LB_IP=""
for server in $LB_HOSTS
do
    host="${server%%:*}"
    ip="${server##*:}"
    K8S_LB_IP+="$ip"
done

HAPROXYLIST=""
for server in $CTRL_HOSTS
do
    host="${server%%:*}"
    ip="${server##*:}"
    HAPROXYLIST+="    server $host $ip:6443 check fall 3 rise 2
"
done

cat <<EOF | tee /etc/haproxy/haproxy.cfg
frontend kubernetes
    bind ${K8S_LB_IP}:6443
    option tcplog
    mode tcp
    default_backend k8s-mnodes

backend k8s-mnodes
    mode tcp
    balance roundrobin
    option tcp-check
${HAPROXYLIST}
EOF
