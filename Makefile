SHELL = /usr/bin/env bash -o pipefail
KIND_CLUSTER_NAME ?= registry-test-cluster
KIND_IMAGE ?= kindest/node:v1.19.1
CLUSTER_NAMESPACE ?= registry-test

KIND = $(shell pwd)/bin/kind

local-cluster-up: kind local-cleanup ## Start a local Kubernetes cluster using Kind
	$(KIND) create cluster --name $(KIND_CLUSTER_NAME) --image $(KIND_IMAGE) --config kind-cluster.yaml

local-cleanup: kind ## Deletes the local Kubernetes cluster started using Kind
	$(KIND) delete cluster --name $(KIND_CLUSTER_NAME)

kind: ## Download kind locally if necessary.
	$(call go-get-tool,$(KIND),sigs.k8s.io/kind@v0.11.1)

# go-get-tool will 'go get' any package $2 and install it to $1.
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
define go-get-tool
@[ -f $(1) ] || { \
set -e ;\
TMP_DIR=$$(mktemp -d) ;\
cd $$TMP_DIR ;\
go mod init tmp ;\
echo "Downloading $(2)" ;\
GOBIN=$(PROJECT_DIR)/bin go get $(2) ;\
rm -rf $$TMP_DIR ;\
}
endef