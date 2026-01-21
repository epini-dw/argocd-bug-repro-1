#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"

REPO=$(git rev-parse --show-toplevel)

MY_UID=$(id -u)
MY_GID=$(id -g)
GIT_DAEMON_IMAGE=nobody/git-daemon:latest

: "${ARGO_VERSION:=v3.3.0-rc3}"
: "${ARGO_NAMESPACE:=argocd}"
: "${ARGO_IMAGE:=}"
: "${TEST_NAMESPACE=test}"
: "${KIND_CLUSTER_NAME:=argo-test-cluster}"
: "${KIND_KUBECONFIG:=${REPO}/kubeconfig.yaml}"
: "${DOCKER_HUB_REGISTRY:=docker.io}"
: "${DOCKER_HUB_REGISTRY:=docker.io}"

export KUBECONFIG="$KIND_KUBECONFIG"

# If sourced from another script, return so the actual setup steps aren't run.
if (return 0) 2>/dev/null; then
	return 0
fi

# ------------------------------------------------------------------------------

# Create the KIND cluster.
# This git repo will be bind-mounted inside the node.
sed 's/^\t//' >kind-config.yaml <<EOF
	kind: Cluster
	apiVersion: kind.x-k8s.io/v1alpha4
	nodes:
	  - role: control-plane
	    extraMounts:
	      - hostPath: "${REPO}"
	        containerPath: /mnt/host/repo
EOF

if ! kind get clusters | grep -Fqx "${KIND_CLUSTER_NAME}"; then
	({
		set -x
		kind create cluster \
			--config kind-config.yaml \
			--name "$KIND_CLUSTER_NAME" \
			--kubeconfig "$KUBECONFIG"
	})
fi

kind get kubeconfig --name "$KIND_CLUSTER_NAME" >"$KUBECONFIG"
kubectl create namespace "$ARGO_NAMESPACE" || true
kubectl create namespace "$TEST_NAMESPACE" || true

# ------------------------------------------------------------------------------

# Build the git-daemon image and load it into the KIND cluster.
({
	set -x

	docker build \
		--build-arg "DOCKER_HUB_REGISTRY=${DOCKER_HUB_REGISTRY}" \
		--tag "$GIT_DAEMON_IMAGE" \
		git-daemon/image

	kind load docker-image \
		--name "$KIND_CLUSTER_NAME" \
		"$GIT_DAEMON_IMAGE"
})

# Deploy a git-daemon service into the `argocd` namespace.
# Export the mounted repo as a git remote accessible from within the cluster.
({
	set -x

	helm template git-daemon/chart \
		--namespace "$ARGO_NAMESPACE" \
		--set "image=${GIT_DAEMON_IMAGE}" \
		--set "uid=${MY_UID}" \
		--set "gid=${MY_GID}" \
		| kubectl replace -f - --force
})

# ------------------------------------------------------------------------------

# Install Argo CD with the source hydrator into the KIND cluster.
# Kustomize it to be less strict about security.
({
	set -x

	URL="https://github.com/argoproj/argo-cd/manifests/cluster-install-with-hydrator/?ref=${ARGO_VERSION}" \
	yq '.resources[0] = strenv(URL)' \
		argo-cd/kustomization.original.yaml \
		>argo-cd/kustomization.yaml

	if [[ -n "$ARGO_IMAGE" ]]; then
		NEW_NAME="${ARGO_IMAGE%%:*}" \
		NEW_TAG="${ARGO_IMAGE#*:}" \
		yq -i '
			.images = (.images // []) + [{
				"name": "quay.io/argoproj/argocd",
				"newName": strenv(NEW_NAME),
				"newTag": strenv(NEW_TAG)
			}]
		' argo-cd/kustomization.yaml
	fi

	kubectl replace --force \
		--namespace "$ARGO_NAMESPACE" \
		--kustomize argo-cd
})

# ------------------------------------------------------------------------------

# Wait for the Argo CD server and LoadBalancer Service to become ready.
({
	set -x

	kubectl wait \
		--namespace "$ARGO_NAMESPACE" \
		--timeout 120s \
		--for jsonpath='{.status.loadBalancer.ingress}' \
		service/argocd-server-lb

	kubectl wait \
		--namespace "$ARGO_NAMESPACE" \
		--timeout 120s \
		--for condition=available \
		deployment/argocd-server
})

# Print the URL to open the Argo CD Web UI.
argo_server_ip=$(
	kubectl get \
		--namespace "$ARGO_NAMESPACE" service/argocd-server-lb \
		-o template --template="{{ (index .status.loadBalancer.ingress 0).ip }}"
)

printf "\n\n\x1B[1m-------------------------------------------------\x1B[m\n"
printf "\x1B[1mArgo CD running at:\x1B[m http://%s\n" "$argo_server_ip"
printf "\x1B[1m-------------------------------------------------\x1B[m\n"
