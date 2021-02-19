#!/usr/bin/env bash

echo ""
echo "Create the kubelet-config.yaml configuration file:"
echo "#########################################################"

cat <<EOF | tee ${CFG_DIR}/kubelet-config.yaml
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "${CFG_DIR}/pki/ca.crt"
authorization:
  mode: Webhook
clusterDomain: k8s.local
clusterDNS:
  - 192.168.5.11
  - 192.168.5.21
  - 192.168.5.22
resolvConf: /run/systemd/resolve/resolv.conf
runtimeRequestTimeout: 15m
EOF

# > The `resolvConf` configuration is used to avoid loops when using CoreDNS for service discovery on systems running `systemd-resolved`.

echo ""
echo "Create the kube-proxy-config.yaml configuration file:"
echo "#########################################################"

cat <<EOF | tee ${CFG_DIR}/kube-proxy-config.yaml
---
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: ${CFG_DIR}/kube-proxy.kubeconfig
mode: iptables
clusterCIDR: 10.42.0.0/16
EOF
