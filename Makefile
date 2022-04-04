SHELL = /usr/bin/env bash -o pipefail
KIND_CLUSTER_NAME ?= registry-test-cluster
KIND_IMAGE ?= kindest/node:v1.23.1
CLUSTER_NAMESPACE ?= registry-test

KIND = $(shell pwd)/bin/kind
TKN = $(shell pwd)/bin/tkn

kind: ## Download kind locally if necessary.
	$(call go-get-tool,$(KIND),sigs.k8s.io/kind@v0.11.1)

bin/tkn: bin
	curl -LO https://github.com/tektoncd/cli/releases/download/v0.23.0/tkn_0.23.0_Linux_x86_64.tar.gz
	sudo tar xvzf tkn_0.23.0_Linux_x86_64.tar.gz -C bin/ tkn
	#chmod +x bin/tkn

bin:
	mkdir -p bin/

local-cluster-up: kind local-cleanup ## Start a local Kubernetes cluster using Kind
	$(KIND) create cluster --name $(KIND_CLUSTER_NAME) --image $(KIND_IMAGE) --config kind-cluster.yaml

local-cleanup: kind ## Deletes the local Kubernetes cluster started using Kind
	$(KIND) delete cluster --name $(KIND_CLUSTER_NAME)

local-setup: local-cluster-up namespace install-registry install-api install-envoy ## Set up a test/dev local Kubernetes server
	kubectl -n $(CLUSTER_NAMESPACE) wait --timeout=500s --for=condition=Available deployments --all
	kubectl port-forward --namespace $(CLUSTER_NAMESPACE) deployment/envoy 8000:8000 &
	@{ \
	echo ;\
	echo "***************************************************************************"; \
	echo "************************** Voilà, profit!!! *******************************"; \
	echo "***************************************************************************"; \
	}


##@ Deployment
namespace: ## Create namespace for registry test.
	kubectl create namespace $(CLUSTER_NAMESPACE)

install-registry: ## Installs registry and its ddbb
	kubectl -n $(CLUSTER_NAMESPACE) apply -f registry-ddbb-deployment.yaml
	kubectl -n $(CLUSTER_NAMESPACE) wait --timeout=100s --for=condition=Available deployments registry-database
	kubectl -n $(CLUSTER_NAMESPACE) apply -f registry-deployment.yaml

install-api: ## Installs the product api
	kubectl -n $(CLUSTER_NAMESPACE) apply -f httpbin-deployment.yaml

install-envoy: ## Installs envoy proxy
	kubectl -n $(CLUSTER_NAMESPACE) apply -f envoy-deployment.yaml


##@ Tekton Pipelines

install-tekton:
	kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
	kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/master/task/git-clone/0.5/git-clone.yaml

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