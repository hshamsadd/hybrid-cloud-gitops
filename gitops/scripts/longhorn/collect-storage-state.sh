#!/usr/bin/env bash
# Run on RHEL. Read-only cluster inspection. No Secrets, kubeconfig contents,
# application environment variables, or Kubernetes mutations are requested.
set -uo pipefail
umask 077
for lh_tool in kubectl jq timeout; do command -v "$lh_tool" >/dev/null || exit 1; done
lh_report=$(mktemp "$HOME/storage-state.XXXXXX.txt")
exec > >(tee "$lh_report") 2>&1
section() { printf '\n--- %s ---\n' "$*"; }
run() { "$@" || printf 'CHECK FAILED (continued): %s\n' "$*"; }
printf 'Report: %s\n' "$lh_report"
date -Is
run kubectl config current-context
section 'NODE STATUS, CAPACITY, LABELS'
kubectl get nodes -o json | jq '[.items[] | {
 name:.metadata.name,ready:[.status.conditions[]|select(.type=="Ready")|.status],
 capacity:.status.capacity,allocatable:.status.allocatable,taints:.spec.taints,
 labels:(.metadata.labels|with_entries(select(.key|test("topology|failure-domain|persistent-storage|longhorn|rustfs|cnpg|always-on|arch"))))
}]'
section 'ALLOCATED RESOURCES ON STORAGE CANDIDATES'
for lh_node in cp-1 cp-2 cp-3 cp-4 worker-01 worker-02; do
  printf '\nNODE %s\n' "$lh_node"
  kubectl describe node "$lh_node" | sed -n '/Allocated resources:/,/Events:/p'
done
section 'MEASURED NODE UTILIZATION (IF METRICS SERVER EXISTS)'
run kubectl top nodes
section 'PVC / PV / LONGHORN VOLUMES / REPLICAS'
run kubectl get pvc -A -o wide
run kubectl get pv -o wide
run kubectl -n longhorn-system get volumes.longhorn.io -o 'custom-columns=NAME:.metadata.name,STATE:.status.state,HEALTH:.status.robustness,SIZE:.spec.size,REPLICAS:.spec.numberOfReplicas,LOCALITY:.spec.dataLocality'
run kubectl -n longhorn-system get replicas.longhorn.io -o 'custom-columns=NAME:.metadata.name,VOLUME:.spec.volumeName,NODE:.spec.nodeID,DISK:.spec.diskID,STATE:.status.currentState'
section 'LONGHORN DISK SPECIFICATIONS AND CONDITIONS'
kubectl -n longhorn-system get nodes.longhorn.io -o json | jq '[.items[]|{name:.metadata.name,spec:.spec,conditions:.status.conditions,diskStatus:.status.diskStatus}]'
section 'LONGHORN SETTINGS'
kubectl -n longhorn-system get settings.longhorn.io -o json | jq '[.items[]|select(.metadata.name|test("^(default-data-path|create-default-disk-labeled-nodes|system-managed-components-node-selector|taint-toleration|storage-minimal-available-percentage|storage-over-provisioning-percentage|replica-zone-soft-anti-affinity|replica-soft-anti-affinity|allow-volume-creation-with-degraded-availability)$"))|{name:.metadata.name,value:.value}]'
section 'LONGHORN POD PLACEMENT'
run kubectl -n longhorn-system get pods -o wide
section 'WORKLOADS / STORAGE CLASSES'
run kubectl -n object-storage get statefulset,pods,pvc,pdb -o wide
run kubectl get clusters.postgresql.cnpg.io -A
run kubectl get storageclasses -o yaml
section 'ARGO APPLICATION SOURCES AND SYNC STATE'
kubectl -n argocd get applications.argoproj.io -o json | jq '[.items[]|{name:.metadata.name,source:(.spec.source|{repoURL,path,chart,targetRevision}),sources:[.spec.sources[]?|{repoURL,path,chart,targetRevision}],automated:.spec.syncPolicy.automated,sync:.status.sync.status,health:.status.health.status}]'
section 'ETCD MEMBERS / STATUS (READ-ONLY; NO SNAPSHOT OR MEMBERSHIP CHANGE)'
run kubectl -n kube-system get pods -l component=etcd -o wide
lh_etcd=$(kubectl -n kube-system get pods -l component=etcd -o json | jq -r '[.items[]|select(.status.phase=="Running")|.metadata.name]|sort|.[0] // empty')
if [[ -n $lh_etcd ]]; then
  for lh_action in members status; do
    lh_args=(member list)
    [[ $lh_action != status ]] || lh_args=(endpoint status --cluster)
    run timeout 30s kubectl -n kube-system exec "$lh_etcd" -- etcdctl \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/kubernetes/pki/etcd/ca.crt \
      --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
      --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
      "${lh_args[@]}" --write-out=table
  done
else
  printf 'No running etcd pod found by component label. Membership remains unverified.\n'
fi
printf '\nAttach this report: %s\n' "$lh_report"
