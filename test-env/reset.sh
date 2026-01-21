#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
source "setup.sh"

warn() {
	printf "\x1B[31m%s\x1B[m\n" "$1"
}

# ------------------------------------------------------------------------------
# Clear the test namespace:

if kubectl version &>/dev/null; then
	({
		set -e

		if ! kubectl get node "${KIND_CLUSTER_NAME}-control-plane" >/dev/null; then
			warn "Could not ensure kubectl is acting on the KIND cluster."
			exit 1
		fi

		resource_types=$(
			kubectl api-resources \
				--namespaced=true \
				--verbs=delete -o name \
				| tr "\n" "," \
				| sed -e 's/,$//'
		)

		({
			set -x
			kubectl delete \
				--namespace "$TEST_NAMESPACE" \
				--all "$resource_types"

			kubectl delete \
				--namespace "$ARGO_NAMESPACE" \
				--all applications,applicationsets,appprojects
		})
	})
fi

# ------------------------------------------------------------------------------
# Reset the repo:

({
	set -e

	if ! git diff --quiet &>/dev/null; then
		warn "Git repo has unstaged changes. Commit or clear them."
		exit 1
	fi

	if ! git diff --staged --quiet &>/dev/null; then
		warn "Git repo has uncommitted changes. Commit or reset them."
		exit 1
	fi

	set -x

	git checkout refs/tags/reset-checkpoint
	git branch -f main
	git checkout main

	git branch -D hydrated || true
	rm "${REPO}/.git/refs/notes/hydrator.metadata" || true
})
