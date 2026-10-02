#!/usr/bin/env bash
set -euo pipefail

NODES=(cp-1 cp-2 cp-3 cp-4)

echo "Checking Kubernetes nodes..."
for NODE in "${NODES[@]}"; do
  kubectl get node "$NODE" >/dev/null
done

configure_node() {
  local node="$1"
  local config="$2"

  echo "Configuring $node"

  kubectl label node "$node" --overwrite \
    node-restriction.kubernetes.io/longhorn-eligible=true \
    node-restriction.kubernetes.io/persistent-storage=true \
    node.longhorn.io/create-default-disk=config

  kubectl annotate node "$node" --overwrite \
    node.longhorn.io/default-disks-config="$config"
}

configure_node cp-1 \
'[{"name":"root-longhorn","path":"/home/longhorn","allowScheduling":true,"storageReserved":21222527385,"tags":[]}]'

configure_node cp-2 \
'[{"name":"root-longhorn","path":"/home/longhorn","allowScheduling":true,"storageReserved":8208671129,"tags":[]}]'

configure_node cp-3 \
'[{"name":"oci-block-100g","path":"/mnt/longhorn-data/longhorn","allowScheduling":true,"storageReserved":10737418240,"tags":["dedicated"]}]'

configure_node cp-4 \
'[{"name":"root-longhorn","path":"/home/longhorn","allowScheduling":true,"storageReserved":8208671129,"tags":[]}]'

echo
echo "Longhorn node bootstrap metadata applied."