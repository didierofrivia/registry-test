SHELL = /usr/bin/env bash -o pipefail
KIND_CLUSTER_NAME ?= registry-test-cluster
KIND_IMAGE ?= kindest/node:v1.23.1
CLUSTER_NAMESPACE ?= registry-test
KAMRAD_REPO_URL ?= https://github.com/3scale-labs/kamrad
KAMRAD_REPO_BRANCH ?= tekton-testing

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
	$(KIND) create cluster --name $(KIND_CLUSTER_NAME) --image $(KIND_IMAGE)

local-cleanup: kind ## Deletes the local Kubernetes cluster started using Kind
	$(KIND) delete cluster --name $(KIND_CLUSTER_NAME)

local-setup: local-cluster-up namespace install-registry install-api install-envoy install-devportal install-tekton ## Set up a test/dev local Kubernetes server
	kubectl -n $(CLUSTER_NAMESPACE) wait --timeout=500s --for=condition=Available deployments --all
	kubectl -n tekton-pipelines wait --timeout=500s --for=condition=Available deployments --all
	$(MAKE) install-pipelines
	kubectl port-forward --namespace $(CLUSTER_NAMESPACE) deployment/envoy 8000:8000 &
	kubectl port-forward  --namespace $(CLUSTER_NAMESPACE) service/devportal 8888:8888 &
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
	kubectl -n $(CLUSTER_NAMESPACE) wait --timeout=500s --for=condition=Available deployments registry-database
	kubectl -n $(CLUSTER_NAMESPACE) apply -f registry-deployment.yaml

install-devportal:
	kubectl -n $(CLUSTER_NAMESPACE) apply -f devportal-pv.yaml
	kubectl -n $(CLUSTER_NAMESPACE) apply -f devportal-pvc.yaml
	kubectl -n $(CLUSTER_NAMESPACE) apply -f devportal-deployment.yaml

install-api: ## Installs the product api
	kubectl -n $(CLUSTER_NAMESPACE) apply -f httpbin-deployment.yaml

install-envoy: ## Installs envoy proxy
	kubectl -n $(CLUSTER_NAMESPACE) apply -f envoy-deployment.yaml


##@ Tekton Pipelines

install-tekton:
	kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.notags.yaml
	kubectl apply -n tekton-pipelines -f https://raw.githubusercontent.com/tektoncd/catalog/master/task/git-clone/0.5/git-clone.yaml

install-pipelines:
	kubectl -n tekton-pipelines apply -f tekton

run-pipeline:
	$(TKN) -n tekton-pipelines pipeline start kamrad-build-deploy \
		--workspace name=kamrad-code-wp,volumeClaimTemplateFile=./tekton/templates/pipeline-workspace-volume-claim.yaml \
		--workspace name=devportal-wp,claimName=devportal-pvc \
		--param repo-url=$(KAMRAD_REPO_URL) \
		--param revision=$(KAMRAD_REPO_BRANCH) \
		-s deployer-sa \
		--showlog


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