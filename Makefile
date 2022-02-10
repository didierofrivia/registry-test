SHELL = /usr/bin/env bash -o pipefail
KIND_CLUSTER_NAME ?= registry-test-cluster
KIND_IMAGE ?= kindest/node:v1.19.1
CLUSTER_NAMESPACE ?= registry-test

local-cluster-up: kind local-cleanup ## Start a local Kubernetes cluster using Kind
	kind create cluster --name $(KIND_CLUSTER_NAME) --image $(KIND_IMAGE) --config kind-cluster.yaml

local-cleanup: kind ## Deletes the local Kubernetes cluster started using Kind
	kind delete cluster --name $(KIND_CLUSTER_NAME)

KIND = $(shell pwd)/bin/kind
kind: ## Download kind locally if necessary.
	$(call go-get-tool,$(KIND),sigs.k8s.io/kind@v0.11.1)

