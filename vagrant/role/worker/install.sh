#!/usr/bin/env bash

echo ""
echo "install docker dependencies"
echo "#########################################################"

apt-get update -qq -y
apt-get install -qq -y apt-transport-https ca-certificates curl software-properties-common

echo ""
echo "add docker repo signing key"
echo "#########################################################"

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -


echo ""
echo "add docker sources list into the sources.list directory"
echo "#########################################################"

add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"


echo ""
echo "install docker"
echo "#########################################################"

apt-get update -qq -y
apt-get install -qq -y docker-ce


echo ""
echo "add vagrant to the docker group"
echo "#########################################################"

usermod -aG docker vagrant

echo ""
echo "docker daemon configuration for systemd cgroup driver"
echo "#########################################################"

mkdir -p /etc/docker/
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

echo ""
echo "enable docker service"
echo "#########################################################"

systemctl enable docker >/dev/null 2>&1
systemctl start docker


echo ""
echo "add sysctl settings"
echo "#########################################################"
(
echo "net.bridge.bridge-nf-call-ip6tables=1"
echo "net.bridge.bridge-nf-call-iptables=1"
) >> /etc/sysctl.d/kubernetes.conf
sysctl --system >/dev/null 2>&1

# Reference : 
#     https://kubernetes.io/docs/setup/release/#node-binaries

echo ""
echo "Download and Install Kubernetes worker Binaries"
echo "#########################################################"

curl -L -o /usr/local/bin/kubectl --silent --show-error \
https://storage.googleapis.com/kubernetes-release/release/v1.18.4/bin/linux/amd64/kubectl
chmod 755 /usr/local/bin/kubectl

curl -L -o /usr/local/bin/kube-proxy --silent --show-error \
https://storage.googleapis.com/kubernetes-release/release/v1.18.4/bin/linux/amd64/kube-proxy
chmod 755 /usr/local/bin/kube-proxy

curl -L -o /usr/local/bin/kubelet --silent --show-error \
https://storage.googleapis.com/kubernetes-release/release/v1.18.4/bin/linux/amd64/kubelet
chmod 755 /usr/local/bin/kubelet

mkdir -p \
  /var/lib/kubernetes \
  /var/run/kubernetes
