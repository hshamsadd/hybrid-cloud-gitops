#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALUES_FILE="${REPO_ROOT}/ansible/files/kubernetes/flannel-values.yaml"

FLANNEL_VERSION="v0.28.9"

helm repo add flannel https://flannel-io.github.io/flannel/ --force-update
helm repo update

helm upgrade --install flannel flannel/flannel \
  --namespace kube-flannel \
  --create-namespace \
  --version "${FLANNEL_VERSION}" \
  --values "${VALUES_FILE}" \
  --wait \
  --timeout 10m

kubectl -n kube-flannel rollout status \
  daemonset/kube-flannel-ds \
  --timeout=10m