#!/usr/bin/env bash

# Each kubeconfig requires a Kubernetes API Server to connect to.
# To support high availability the IP address assigned to the load balancer will be used.

# Reference:
#     https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
#     https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/
#     https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/
#     https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/
#     https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

echo ""
echo "Generate a kubeconfig file for the kube-proxy service:"
echo "#########################################################"

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=${CFG_DIR}/pki/ca.crt \
  --embed-certs=true \
  --server=https://${LB_IP}:6443 \
  --kubeconfig=${CFG_DIR}/kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=${CFG_DIR}/pki/kube-proxy.crt \
  --client-key=${CFG_DIR}/pki/kube-proxy.key \
  --embed-certs=true \
  --kubeconfig=${CFG_DIR}/kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-proxy \
  --kubeconfig=${CFG_DIR}/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=${CFG_DIR}/kube-proxy.kubeconfig


echo ""
echo "Generate a kubeconfig file for the kube-controller-manager service:"
echo "#########################################################"

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=${CFG_DIR}/pki/ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=${CFG_DIR}/pki/kube-controller-manager.crt \
  --client-key=${CFG_DIR}/pki/kube-controller-manager.key \
  --embed-certs=true \
  --kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-controller-manager \
  --kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig


echo ""
echo "Generate a kubeconfig file for the kube-scheduler service:"
echo "#########################################################"

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=${CFG_DIR}/pki/ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=${CFG_DIR}/pki/kube-scheduler.crt \
  --client-key=${CFG_DIR}/pki/kube-scheduler.key \
  --embed-certs=true \
  --kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-scheduler \
  --kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig


echo ""
echo "Generate a kubeconfig file for the admin user:"
echo "#########################################################"

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=${CFG_DIR}/pki/ca.crt \
  --embed-certs=true \
  --server=https://${LB_IP}:6443 \
  --kubeconfig=${CFG_DIR}/admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=${CFG_DIR}/pki/admin.crt \
  --client-key=${CFG_DIR}/pki/admin.key \
  --embed-certs=true \
  --kubeconfig=${CFG_DIR}/admin.kubeconfig

kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=admin \
  --kubeconfig=${CFG_DIR}/admin.kubeconfig

kubectl config use-context default --kubeconfig=${CFG_DIR}/admin.kubeconfig

# copy admin.kubeconfig to vagrant user space
mkdir -p /home/vagrant/.kube
cp ${CFG_DIR}/admin.kubeconfig /home/vagrant/.kube/config
chown -R vagrant /home/vagrant/.kube/

echo ""
echo "Generate a kubeconfig file for each worker node:"
echo "#########################################################"

for server in $WORK_HOSTS; do

  host="${server%%:*}"

  kubectl config set-cluster ${CLUSTER_NAME} \
    --certificate-authority=${CFG_DIR}/pki/ca.crt \
    --embed-certs=true \
    --server=https://${LB_IP}:6443 \
    --kubeconfig=${CFG_DIR}/"${host}.kubeconfig"

  kubectl config set-credentials "system:node:${host}" \
    --client-certificate=${CFG_DIR}/pki/"${host}.crt" \
    --client-key="${CFG_DIR}/pki/${host}.key" \
    --embed-certs=true \
    --kubeconfig=${CFG_DIR}/"${host}.kubeconfig"

  kubectl config set-context default \
    --cluster=${CLUSTER_NAME} \
    --user=system:node:"${host}" \
    --kubeconfig=${CFG_DIR}/"${host}.kubeconfig"

  kubectl config use-context default --kubeconfig=${CFG_DIR}/"${host}.kubeconfig"
done
