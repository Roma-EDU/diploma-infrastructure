#!/bin/bash
#set -e

cd infrastructure
echo 'Building infrastructure...'
TF_IN_AUTOMATION=1 terraform apply -auto-approve

echo 'Gathering infrastructure results...'
SUPPLEMENTARY_ADDRESSES=$(terraform output -json instance_group_masters_public_ips | tr -d '"[]')
INTERNAL_ADDRESSES=$(terraform output -json instance_group_masters_private_ips | tr -d '"[]')
GENERATE_CMD=$(. get-infrastructure.sh)

echo 'Generating hosts.yaml...'
cd ../automation
(set -- word && eval "$GENERATE_CMD")

echo 'Recreating cluster configuration...'
rm -rf ../kubespray/inventory/mycluster
cp -rfp ../kubespray/inventory/sample ../kubespray/inventory/mycluster
mv hosts.yaml ../kubespray/inventory/mycluster/hosts.yaml
#cp -rf addons.yml ../kubespray/inventory/mycluster/group_vars/k8s_cluster/addons.yml
cp -rf k8s-cluster.yml ../kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i -e "s/MASTER_PUBLIC_IPS_TO_REPLACE/${SUPPLEMENTARY_ADDRESSES}/g" ../kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

echo 'Running ansible...'
cd ../kubespray
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i inventory/mycluster/hosts.yaml ../automation/wait-cluster-reachable.yml -b -v
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml -b -v
if [ ! -f inventory/mycluster/artifacts/admin.conf ]; then
    ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml -b -v
fi
if [ ! -f inventory/mycluster/artifacts/admin.conf ]; then
    exit 1
fi

echo 'Updating kube-config...'
sed -i -- "s/${INTERNAL_ADDRESSES%,*}/${SUPPLEMENTARY_ADDRESSES%,*}/g" inventory/mycluster/artifacts/admin.conf
cp -rf inventory/mycluster/artifacts/admin.conf $HOME/.kube/config

echo 'Updating monitoring...'
cd ../monitoring
kubectl apply --server-side -f manifests/setup
kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring
kubectl apply -f manifests/

cd ..
kubectl apply -f cluster/

echo '$ kubectl get all --all-namespaces'
kubectl get all --all-namespaces

echo "Grafana      http://${SUPPLEMENTARY_ADDRESSES%,*}:31001"
echo "Application  http://${SUPPLEMENTARY_ADDRESSES%,*}:30001"