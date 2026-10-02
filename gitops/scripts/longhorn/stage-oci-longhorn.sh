#!/usr/bin/env bash
# HISTORICAL ONE-TIME registration helper used during initial cp-3 setup.
# Normal rebuild/bootstrap path is configure-storage-nodes.sh.
# Ran on RHEL using your existing kubectl context, AFTER OCI setup succeeded.
# Adds a disabled disk to cp-3; preserves existing disks, data, labels, and
# node-level scheduling. Does not enable workload placement or delete resources.
set -Eeuo pipefail
umask 077
[[ ${1:-} == --oci-mount-verified ]] || { printf 'Usage: bash stage-oci-longhorn.sh --oci-mount-verified\n' >&2; exit 1; }
for lh_tool in kubectl jq; do command -v "$lh_tool" >/dev/null; done
lh_backup=$(mktemp -d "$HOME/longhorn-oci-registration.XXXXXX")
printf 'Context: '; kubectl config current-context
printf 'Registration backup: %s\n' "$lh_backup"
kubectl get node cp-3 -o json > "$lh_backup/kubernetes-cp-3.json"
jq -e 'any(.status.addresses[]; .type == "InternalIP" and .address == "100.110.252.128") and .status.nodeInfo.architecture == "arm64"' "$lh_backup/kubernetes-cp-3.json" >/dev/null
kubectl -n longhorn-system get nodes.longhorn.io cp-3 -o json > "$lh_backup/longhorn-cp-3.before.json"
lh_key=oci-block-100g
lh_path=/mnt/longhorn-data/longhorn
if jq -e --arg key "$lh_key" '.spec.disks | has($key)' "$lh_backup/longhorn-cp-3.before.json" >/dev/null; then
  jq -e --arg key "$lh_key" --arg path "$lh_path" '.spec.disks[$key].path == $path' "$lh_backup/longhorn-cp-3.before.json" >/dev/null
  printf 'Disk key already exists at the correct path; leaving it unchanged.\n'
else
  jq -e --arg path "$lh_path" '.spec.disks | type == "object"' "$lh_backup/longhorn-cp-3.before.json" >/dev/null
  jq -e --arg path "$lh_path" 'all(.spec.disks[]; .path != $path)' "$lh_backup/longhorn-cp-3.before.json" >/dev/null
  jq --arg key "$lh_key" --arg path "$lh_path" '[
    {op:"test",path:"/metadata/resourceVersion",value:.metadata.resourceVersion},
    {op:"add",path:("/spec/disks/"+$key),value:{
      path:$path,diskType:"filesystem",allowScheduling:false,
      evictionRequested:false,storageReserved:10737418240,tags:["dedicated"]
    }}
  ]' "$lh_backup/longhorn-cp-3.before.json" > "$lh_backup/add-disk.patch.json"
  kubectl -n longhorn-system patch nodes.longhorn.io cp-3 --type=json --patch-file "$lh_backup/add-disk.patch.json"
fi
lh_ready=false
for lh_attempt in {1..30}; do
  kubectl -n longhorn-system get nodes.longhorn.io cp-3 -o json > "$lh_backup/longhorn-cp-3.after.json"
  if jq -e --arg key "$lh_key" '(.status.diskStatus[$key].storageMaximum // 0) > 0 and any(.status.diskStatus[$key].conditions[]?; .type == "Ready" and .status == "True")' "$lh_backup/longhorn-cp-3.after.json" >/dev/null; then
    lh_ready=true
    break
  fi
  sleep 2
done
jq --arg key "$lh_key" '{node:.metadata.name,nodeScheduling:.spec.allowScheduling,newDisk:.spec.disks[$key],newDiskStatus:.status.diskStatus[$key]}' "$lh_backup/longhorn-cp-3.after.json"
if [[ $lh_ready != true ]]; then
  printf 'STOP: disk not Ready yet. Preserve the report; do not delete disk config or force formatting.\n' >&2
  exit 1
fi
printf 'NEW DISK READY. It remains disabled for scheduling until capacity and placement are checked.\n'
