# Always use devbox environment to run commands.
set shell := ["devbox", "run"]
# Load dotenv
set dotenv-load

default:
  @just --list

lint:
  @tofu fmt -check -recursive .
  @tflint --recursive

GATEWAY_API_VERSION := "v1.1.0"
PROMETHEUS_CRDS_VERSION := "main"

modules-cluster-manifests:
  @rm -rf k8s.tjo.cloud/modules/cluster/manifests
  @mkdir -p k8s.tjo.cloud/modules/cluster/manifests
  @curl -L -o k8s.tjo.cloud/modules/cluster/manifests/gateway-api.crds.yaml \
    "https://github.com/kubernetes-sigs/gateway-api/releases/download/{{GATEWAY_API_VERSION}}/experimental-install.yaml"

module-cluster-core-manifests:
  @rm -rf k8s.tjo.cloud/modules/cluster-core/manifests
  @mkdir -p k8s.tjo.cloud/modules/cluster-core/manifests
  @curl -L -o k8s.tjo.cloud/modules/cluster-core/manifests/crd-podmonitors.yaml \
    "https://raw.githubusercontent.com/prometheus-community/helm-charts/{{PROMETHEUS_CRDS_VERSION}}/charts/kube-prometheus-stack/charts/crds/crds/crd-podmonitors.yaml"
  @curl -L -o k8s.tjo.cloud/modules/cluster-core/manifests/crd-servicemonitors.yaml \
    "https://raw.githubusercontent.com/prometheus-community/helm-charts/{{PROMETHEUS_CRDS_VERSION}}/charts/kube-prometheus-stack/charts/crds/crds/crd-servicemonitors.yaml"

k8s-apply: modules-cluster-manifests module-cluster-core-manifests
  tofu -chdir={{justfile_directory()}}/k8s.tjo.cloud init
  tofu -chdir={{justfile_directory()}}/k8s.tjo.cloud apply -target module.cluster
  tofu -chdir={{justfile_directory()}}/k8s.tjo.cloud apply -target module.cluster-core
  tofu -chdir={{justfile_directory()}}/k8s.tjo.cloud apply
