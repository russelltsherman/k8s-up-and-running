#!/usr/bin/env bash

# In this script we will bootstrap the Kubernetes control plane across 2 compute instances and configure it for high availability. 
# You will also create an external load balancer that exposes the Kubernetes API Servers to remote clients. 
# The following components will be installed on each node: Kubernetes API Server, Scheduler, and Controller Manager.

# This script must be run on each controller instance: `k8s-m1`, and `k8s-m2`.

# Reference : 
#     https://kubernetes.io/docs/setup/release/#server-binaries

# The instance internal IP address will be used to advertise the API Server to members of the cluster. 
# Retrieve the internal IP address for the current compute instance:
INTERNAL_IP=$(ip addr show eth1 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
export INTERNAL_IP

echo ""
echo "Create the kube-apiserver.service systemd unit file:"
echo "#########################################################"

ETCD_CLUSTER=""
for server in ${ETCD_HOSTS}
do
  ip="${server##*:}"
  ETCD_CLUSTER+="https://${ip}:2379,"
done
ETCD_CLUSTER="${ETCD_CLUSTER%?}"

cat <<EOF | tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=${PKI_DIR}/ca.crt \\
  --enable-admission-plugins=NodeRestriction,ServiceAccount \\
  --enable-swagger-ui=true \\
  --enable-bootstrap-token-auth=true \\
  --etcd-cafile=${PKI_DIR}/ca.crt \\
  --etcd-certfile=${PKI_DIR}/etcd-server.crt \\
  --etcd-keyfile=${PKI_DIR}/etcd-server.key \\
  --etcd-servers=${ETCD_CLUSTER} \\
  --event-ttl=1h \\
  --encryption-provider-config=${CFG_DIR}/encryption-config.yaml \\
  --kubelet-certificate-authority=${PKI_DIR}/ca.crt \\
  --kubelet-client-certificate=${PKI_DIR}/kube-apiserver.crt \\
  --kubelet-client-key=${PKI_DIR}/kube-apiserver.key \\
  --kubelet-https=true \\
  --runtime-config=api/all=true \\
  --service-account-key-file=${PKI_DIR}/service-account.crt \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=${PKI_DIR}/kube-apiserver.crt \\
  --tls-private-key-file=${PKI_DIR}/kube-apiserver.key \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


echo ""
echo "Create the kube-controller-manager.service systemd unit file:"
echo "#########################################################"

cat <<EOF | tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --allocate-node-cidrs=true \\
  --cluster-cidr=10.42.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=${PKI_DIR}/ca.crt \\
  --cluster-signing-key-file=${PKI_DIR}/ca.key \\
  --kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=${PKI_DIR}/ca.crt \\
  --service-account-private-key-file=${PKI_DIR}/service-account.key \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


echo ""
echo "Create the kube-scheduler.service systemd unit file:"
echo "#########################################################"

cat <<EOF | tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig \\
  --address=127.0.0.1 \\
  --leader-elect=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


echo ""
echo "Create the etcd.service systemd unit file:"
echo "#########################################################"

ETCD_CLUSTER=""
for server in ${ETCD_HOSTS}
do
  host="${server%%:*}"
  ip="${server##*:}"
  ETCD_CLUSTER+="${host}=https://${ip}:2380,"
done
ETCD_CLUSTER="${ETCD_CLUSTER%?}"

cat <<EOF | tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name=$(hostname -s) \\
  --cert-file=${PKI_DIR}/etcd-server.crt \\
  --key-file=${PKI_DIR}/etcd-server.key \\
  --peer-cert-file=${PKI_DIR}/etcd-server.crt \\
  --peer-key-file=${PKI_DIR}/etcd-server.key \\
  --trusted-ca-file=${PKI_DIR}/ca.crt \\
  --peer-trusted-ca-file=${PKI_DIR}/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster ${ETCD_CLUSTER} \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


echo ""
echo "Start the Controller Services"
echo "#########################################################"

systemctl daemon-reload
systemctl enable kube-apiserver kube-controller-manager kube-scheduler etcd
systemctl start kube-apiserver kube-controller-manager kube-scheduler etcd
