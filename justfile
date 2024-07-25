# Always use devbox environment to run commands.
set shell := ["devbox", "run"]
# Load dotenv
set dotenv-load

lint:
  @tofu fmt -check -recursive .
  @tflint --recursive

GATEWAY_API_VERSION := "v1.1.0"
METRICS_SERVER_VERSION := "v0.7.1"

modules-cluster-manifests:
  @rm -rf modules/cluster/manifests
  @mkdir -p modules/cluster/manifests
  @curl -L -o modules/cluster/manifests/gateway-api.crds.yaml \
    "https://github.com/kubernetes-sigs/gateway-api/releases/download/{{GATEWAY_API_VERSION}}/experimental-install.yaml"
  @curl -L -o modules/cluster/manifests/metrics-server.yaml \
    "https://github.com/kubernetes-sigs/metrics-server/releases/download/{{METRICS_SERVER_VERSION}}/components.yaml"

k8s-apply: modules-cluster-manifests
  tofu -chdir={{justfile_directory()}}/k8s.tjo.cloud init
  tofu -chdir={{justfile_directory()}}/k8s.tjo.cloud apply -target module.cluster
  tofu -chdir={{justfile_directory()}}/k8s.tjo.cloud apply -target module.cluster-core
  tofu -chdir={{justfile_directory()}}/k8s.tjo.cloud apply
