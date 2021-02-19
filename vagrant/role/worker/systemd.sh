#!/usr/bin/env bash

echo ""
echo "Create the kubelet.service systemd unit file:"
echo "#########################################################"

cat <<EOF | tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=${CFG_DIR}/kubelet-config.yaml \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=${CFG_DIR}/${HOSTNAME}.kubeconfig \\
  --tls-cert-file=${PKI_DIR}/${HOSTNAME}.crt \\
  --tls-private-key-file=${PKI_DIR}/${HOSTNAME}.key \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


echo ""
echo "Create the kube-proxy.service systemd unit file:"
echo "#########################################################"

cat <<EOF | tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=${CFG_DIR}/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "Start the Worker Services"
echo "#########################################################"

systemctl daemon-reload
systemctl enable kubelet kube-proxy
systemctl start kubelet kube-proxy
