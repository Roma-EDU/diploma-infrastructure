#!/bin/bash
#set -e

cd infrastructure
echo "Building infrastructure..."
TF_IN_AUTOMATION=1 terraform apply -auto-approve

echo "Gathering infrastructure results..."
SUPPLEMENTARY_ADDRESSES=$(terraform output -json instance_group_masters_public_ips | tr -d '"[]')
INTERNAL_ADDRESSES=$(terraform output -json instance_group_masters_private_ips | tr -d '"[]')
GENERATE_CMD=$(. get-infrastructure.sh)

echo "Generating hosts.yaml..."
cd ../automation
(set -- word && eval "$GENERATE_CMD")

echo "Recreating cluster configuration..."
rm -rf ../kubespray/inventory/mycluster
cp -rfp ../kubespray/inventory/sample ../kubespray/inventory/mycluster
mv hosts.yaml ../kubespray/inventory/mycluster/hosts.yaml
cp -rf k8s-cluster.yml ../kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i -e "s/MASTER_PUBLIC_IPS_TO_REPLACE/${SUPPLEMENTARY_ADDRESSES}/g" ../kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

echo "Running ansible..."
cd ../kubespray
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i inventory/mycluster/hosts.yaml ../automation/wait-cluster-reachable.yml -b -v
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml -b -v

echo "Updating kube-config..."
sed -i -- "s/${INTERNAL_ADDRESSES%,*}/${SUPPLEMENTARY_ADDRESSES%,*}/g" inventory/mycluster/artifacts/admin.conf
cp -rf inventory/mycluster/artifacts/admin.conf $HOME/.kube/config

cd ..
kubectl get pods --all-namespaces