#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
source "setup.sh"

# ------------------------------------------------------------------------------
set +e -x

kind delete cluster \
	--name "$KIND_CLUSTER_NAME"

rm kind-config.yaml
rm argo-cd/kustomization.yaml
rm "$KIND_KUBECONFIG"
