#!/usr/bin/env bash

# In this script you will provision a PKI Infrastructure using the popular openssl tool, then use it to bootstrap a cert Authority, and generate TLS certs for the following components: etcd, kube-apiserver, kube-controller-manager, kube-scheduler, kubelet, and kube-proxy.

# Reference : 
#     https://en.wikipedia.org/wiki/Public_key_infrastructure
#     https://kubernetes.io/docs/concepts/cluster-administration/certificates/#openssl


echo ""
echo "Install OpenSSL"
echo "#########################################################"
apt-get update -qq -y
apt-get install -qq -y openssl


# Comment line starting with RANDFILE in /etc/ssl/openssl.cnf definition to avoid permission issues
sed -i '0,/RANDFILE/{s/RANDFILE/\#&/}' /etc/ssl/openssl.cnf

generate_ca_cert() {
    local file="$1"
    local subj="$2"
    (
        # Create private key
        openssl genrsa -out "$PKI_DIR/$file.key" "$BITSIZE"
        # Create CSR using the private key
        openssl req -new -key "$PKI_DIR/$file.key" -subj "$subj" -out "$file.csr"
        # Self sign the csr using its own private key
        openssl x509 -req -in  "$file.csr" -signkey "$PKI_DIR/$file.key" -CAcreateserial -out "$PKI_DIR/$file.crt" -days "$DAYS"
    ) 2>/dev/null
    openssl x509 -in "$PKI_DIR/$file.crt" -text
}

generate_cert() {
    local file="$1"
    local subj="$2"
    local extra="$3"
    (
        # Create private key
        openssl genrsa -out "$PKI_DIR/$file.key" "$BITSIZE"
        # Create CSR using the private key
        openssl req -new -key "$PKI_DIR/$file.key" -subj "$subj" -out "$file.csr"
        # Sign the CSR using the CA private key
        openssl x509 -req -in "$file.csr" -CA "$PKI_DIR/ca.crt" -CAkey "$PKI_DIR/ca.key" -CAcreateserial -out "$PKI_DIR/$file.crt" $extra -days "$DAYS"
    ) 2>/dev/null
    openssl x509 -in "$PKI_DIR/$file.crt" -text
}


echo ""
echo "Create a CA cert"
echo "#########################################################"
generate_ca_cert "ca" "/CN=KUBERNETES-CA"


echo ""
echo "Create the admin client cert and private key"
echo "#########################################################"
generate_cert "admin" "/CN=admin/O=system:masters"
# Note that the admin user is part of the **system:masters** group. 
# This is how we are able to perform any administrative operations on Kubernetes cluster using kubectl utility.


echo ""
echo "Create the ETCD cert and private key:"
echo "#########################################################"

ALT_NAMES=""
i=1
for server in $ETCD_HOSTS
do
    ip="${server##*:}"
    ALT_NAMES+="IP.${i} = ${ip}
"
    ((i=i+1))
done
ALT_NAMES+="IP.${i} = 127.0.0.1
"

# ETCD server cert must have addresses of all the servers part of the ETCD cluster
cat > sslconf-etcd.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
${ALT_NAMES}
EOF

generate_cert "etcd-server" "/CN=etcd-server" "-extensions v3_req -extfile sslconf-etcd.cnf"


echo ""
echo "Generates certs for kube-apiserver"
echo "#########################################################"

ALT_NAMES="IP.1 = 10.32.0.1
"
i=2
for server in $LB_HOSTS
do
    ip="${server##*:}"
    ALT_NAMES+="IP.${i} = ${ip}
"
    ((i=i+1))
done
for server in $CTRL_HOSTS
do
    ip="${server##*:}"
    ALT_NAMES+="IP.${i} = ${ip}
"
    ((i=i+1))
done
ALT_NAMES+="IP.${i} = 127.0.0.1
"

# The kube-apiserver cert requires all names that various components may reach it to be part of the alternate names. 
# These include the different DNS names, and IP addresses such as the master servers IP address, the load balancers IP address, the kube-api service IP address etc.
cat > sslconf-kube-apiserver.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
${ALT_NAMES}
EOF

generate_cert "kube-apiserver" "/CN=kube-apiserver" "-extensions v3_req -extfile sslconf-kube-apiserver.cnf"


echo ""
echo "Create the kube-controller-manager client cert and private key"
echo "#########################################################"
generate_cert "kube-controller-manager" "/CN=system:kube-controller-manager"


echo ""
echo "Create the kube-proxy client cert and private key:"
echo "#########################################################"
generate_cert "kube-proxy" "/CN=system:kube-proxy"


echo ""
echo "Create the kube-scheduler client cert and private key:"
echo "#########################################################"
generate_cert "kube-scheduler" "/CN=system:kube-scheduler"


echo ""
echo "Create the service-account cert and private key:"
echo "#########################################################"
generate_cert "service-account" "/CN=service-accounts"


echo ""
echo "Generate cert and private key for each Worker node"
echo "#########################################################"

for server in ${WORK_HOSTS}
do

host="${server%%:*}"
ip="${server##*:}"

cat > sslconf-${host}.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${host}
IP.1 = ${ip}
EOF

generate_cert "${host}" "/CN=system:node:${host}/O=system:nodes" "-extensions v3_req -extfile sslconf-${host}.cnf"

done
