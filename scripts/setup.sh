#!/usr/bin/env zsh
set -euo pipefail

# Config
CLUSTER_NAME="argocd-lab"
K8S_VERSION="v1.29.4"
ARGOCD_NAMESPACE="argocd"
AIRFLOW_NAMESPACE="airflow"

# Utilities
log() { echo "[setup] $1"; }
retry() {
  local attempts=${1}; shift
  local delay=${1}; shift
  local cmd=("$@")
  local n=0
  until "${cmd[@]}"; do
    n=$((n+1))
    if [ $n -ge $attempts ]; then
      return 1
    fi
    sleep "$delay"
  done
}

# Check dependencies
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: '$1' is not installed or not on PATH." >&2
    exit 1
  fi
}

require_cmd kind
require_cmd kubectl
require_cmd helm

# Create kind cluster if not exists
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  log "Creating kind cluster '${CLUSTER_NAME}'"
  cat <<EOF > /tmp/${CLUSTER_NAME}-kind.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
EOF
  kind create cluster --name "$CLUSTER_NAME" --config "/tmp/${CLUSTER_NAME}-kind.yaml" --image "kindest/node:${K8S_VERSION}"
else
  log "Kind cluster '${CLUSTER_NAME}' already exists"
fi

# Ensure kube context
kubectl cluster-info >/dev/null

# Create namespaces
kubectl get ns "$ARGOCD_NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$ARGOCD_NAMESPACE"
kubectl get ns "$AIRFLOW_NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$AIRFLOW_NAMESPACE"

# Add Helm repos
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo add apache-airflow https://airflow.apache.org >/dev/null
helm repo update >/dev/null

# Install/upgrade Argo CD
log "Installing Argo CD via Helm"
helm upgrade --install argocd argo/argo-cd \
  --namespace "$ARGOCD_NAMESPACE" \
  --create-namespace \
  -f k8s/argocd/values.yaml

# Wait for Argo CD to be ready
log "Waiting for Argo CD pods to be ready"
retry 30 5 kubectl rollout status deployment/argocd-server -n "$ARGOCD_NAMESPACE"
retry 30 5 kubectl rollout status deployment/argocd-repo-server -n "$ARGOCD_NAMESPACE"
retry 30 5 kubectl rollout status deployment/argocd-application-controller -n "$ARGOCD_NAMESPACE"

# Expose Argo CD UI via port-forward in background (optional)
if ! pgrep -f "kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE}" >/dev/null; then
  log "Starting port-forward for Argo CD server at https://localhost:8080"
  nohup kubectl port-forward svc/argocd-server -n "$ARGOCD_NAMESPACE" 8080:443 >/tmp/argocd-port-forward.log 2>&1 &
fi

# Bootstrap Argo CD Applications (App of Apps)
log "Applying Argo CD App of Apps"
kubectl apply -n "$ARGOCD_NAMESPACE" -f argocd/apps/app-of-apps.yaml

# Wait for Airflow Application sync (best-effort)
log "Waiting for Airflow namespace resources"
retry 24 5 kubectl get pods -n "$AIRFLOW_NAMESPACE"

log "Setup complete"
log "Argo CD UI: https://localhost:8080"
log "Default admin password (initial):"
kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 --decode || echo "(may have been auto-rotated or disabled in values)"
