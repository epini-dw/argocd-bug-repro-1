# Argo CD Issue #26154 Demonstration

Repository to demonstrate how to reproduce issue [#26154](https://github.com/argoproj/argo-cd/issues/26154) of Argo CD.

 - [scenario-1](./scenario-1/) — Manual apply
 - [scenario-2](./scenario-2/) — ApplicationSet
 - [scenario-3](./scenario-3/) — App of Apps Pattern
 - [scenario-4](./scenario-4/) — App Parameters (new as of 2026-03-13)

## Setup

I provided a [setup script](test-env/setup.sh) to automatically create a test
environment that makes it easy to reproduce the issue. It does the following:

 * Creates a KIND cluster with the local clone of this repo bind-mounted onto the node's host path.
 * Applies a git-daemon Pod, providing read-write access to the bind-mounted repo as `git://git-daemon/`
 * Applies an installation of Argo CD with the source hydrator enabled.

Before starting the setup script, `cloud-provider-kind` should already be
running.

### Requirements

 * [Docker](https://www.docker.com/) Desktop v4.55.0 / Engine v29.1.3
 * [helm](https://helm.sh/) v4.0.4
 * [KIND](https://kind.sigs.k8s.io/) v0.31.0
 * [kubectl](https://kubernetes.io/docs/reference/kubectl/) v1.35.0
 * [mikefarah/yq](https://github.com/mikefarah/yq/) v4.50.1
 * [cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind)

The scripts have been tested on an aarch64 Mac running macOS 26.2. I haven't
tested it on Linux, but I tried to avoid using anything specific to the
Mac/BSD versions of executables.
