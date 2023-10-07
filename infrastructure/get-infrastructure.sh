#!/bin/bash
set -e

# reading terraform output (arrays of values) and removing symbols '[' , ']' and '"'
MASTER_HOSTS_OUTPUT=$(terraform output -json instance_group_masters_host_names | tr -d '"[]')
MASTER_PUBLIC_IPS_OUTPUT=$(terraform output -json instance_group_masters_public_ips | tr -d '"[]')
MASTER_PRIVATE_IPS_OUTPUT=$(terraform output -json instance_group_masters_private_ips | tr -d '"[]')

WORKER_HOSTS_OUTPUT=$(terraform output -json instance_group_workers_host_names | tr -d '"[]')
WORKER_PUBLIC_IPS_OUTPUT=$(terraform output -json instance_group_workers_public_ips | tr -d '"[]')
WORKER_PRIVATE_IPS_OUTPUT=$(terraform output -json instance_group_workers_private_ips | tr -d '"[]')

# converting output to bash arrays, splitting them by ','
IFS=',' read -a MASTER_HOSTS <<< "${MASTER_HOSTS_OUTPUT}"
IFS=',' read -a MASTER_PUBLIC_IPS <<< "${MASTER_PUBLIC_IPS_OUTPUT}"
IFS=',' read -a MASTER_PRIVATE_IPS <<< "${MASTER_PRIVATE_IPS_OUTPUT}"

IFS=',' read -a WORKER_HOSTS <<< "${WORKER_HOSTS_OUTPUT}"
IFS=',' read -a WORKER_PUBLIC_IPS <<< "${WORKER_PUBLIC_IPS_OUTPUT}"
IFS=',' read -a WORKER_PRIVATE_IPS <<< "${WORKER_PRIVATE_IPS_OUTPUT}"

# genetating command to run inventory.py with actual arguments 
MASTERS_COUNT=${#MASTER_HOSTS[@]}
GENERATE_CMD="CONFIG_FILE=hosts.yaml KUBE_CONTROL_HOSTS=${MASTERS_COUNT} ANSIBLE_USER=ubuntu python3 inventory.py"
for ((i = 0; i < MASTERS_COUNT; i++ ))
do
    # format: host_name,ip,access_ip
    GENERATE_CMD+=" ${MASTER_HOSTS[i]},${MASTER_PRIVATE_IPS[i]},${MASTER_PUBLIC_IPS[i]}"
done

WORKERS_COUNT=${#WORKER_HOSTS[@]}
for ((i = 0; i < WORKERS_COUNT; i++ ))
do
    GENERATE_CMD+=" ${WORKER_HOSTS[i]},${WORKER_PRIVATE_IPS[i]},${WORKER_PUBLIC_IPS[i]}"
done

printf "${GENERATE_CMD}"