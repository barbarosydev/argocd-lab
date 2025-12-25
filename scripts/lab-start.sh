#!/usr/bin/env zsh
set -euo pipefail

# lab-start.sh: start local lab with Kind + Argo CD + Helm
# Usage:
#   scripts/lab-start.sh \
#     --cluster-name argocd-lab \
#     --k8s-version v1.29.4 \
#     --kind-config ./k8s/kind/config.yaml \
#     --argocd-namespace argocd \
#     --airflow-namespace airflow \
#     --argo-values ./k8s/argocd/values.yaml \
#     --apps-path ./argocd/apps
# All flags are optional. Defaults are sensible for local dev.

# Defaults
CLUSTER_NAME=${CLUSTER_NAME:-argocd-lab}
K8S_VERSION=${K8S_VERSION:-v1.35.0}
KIND_CONFIG=${KIND_CONFIG:-}
ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-argocd}
AIRFLOW_NAMESPACE=${AIRFLOW_NAMESPACE:-airflow}
ARGO_VALUES=${ARGO_VALUES:-k8s/argocd/values.yaml}
APPS_PATH=${APPS_PATH:-argocd/apps}

log() { echo "[lab-start] $1"; }
err() { echo "[lab-start] ERROR: $1" >&2; }

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --cluster-name NAME         Kind cluster name (default: ${CLUSTER_NAME})
  --k8s-version VERSION       Kind node image tag (default: ${K8S_VERSION})
  --kind-config PATH          Path to Kind cluster config YAML (default: auto-generate minimal config)
  --argocd-namespace NAME     Namespace for Argo CD (default: ${ARGOCD_NAMESPACE})
  --airflow-namespace NAME    Namespace for Airflow (default: ${AIRFLOW_NAMESPACE})
  --argo-values PATH          Helm values for Argo CD install (default: ${ARGO_VALUES})
  --apps-path PATH            Path for Argo CD apps (App of Apps) (default: ${APPS_PATH})
  -h, --help                  Show this help

Environment overrides supported: CLUSTER_NAME, K8S_VERSION, KIND_CONFIG, ARGOCD_NAMESPACE, AIRFLOW_NAMESPACE, ARGO_VALUES, APPS_PATH.
EOF
}

# Parse args (supports --flag value and --flag=value)
while [[ ${#} -gt 0 ]]; do
  key=${1}
  val=""
  if [[ ${key} == *=* ]]; then
    val=${key#*=}
    key=${key%%=*}
    shift 1
  fi
  case "${key}" in
    --cluster-name)
      if [[ -z "${val}" ]]; then val=${2:-}; fi
      [[ -z "${val}" ]] && { err "--cluster-name requires a value"; usage; exit 1; }
      CLUSTER_NAME=${val}
      [[ ${#} -gt 0 && ${1} != --* ]] && shift 1
      ;;
    --k8s-version)
      if [[ -z "${val}" ]]; then val=${2:-}; fi
      [[ -z "${val}" ]] && { err "--k8s-version requires a value"; usage; exit 1; }
      K8S_VERSION=${val}
      [[ ${#} -gt 0 && ${1} != --* ]] && shift 1
      ;;
    --kind-config)
      if [[ -z "${val}" ]]; then val=${2:-}; fi
      [[ -z "${val}" ]] && { err "--kind-config requires a value"; usage; exit 1; }
      KIND_CONFIG=${val}
      [[ ${#} -gt 0 && ${1} != --* ]] && shift 1
      ;;
    --argocd-namespace)
      if [[ -z "${val}" ]]; then val=${2:-}; fi
      [[ -z "${val}" ]] && { err "--argocd-namespace requires a value"; usage; exit 1; }
      ARGOCD_NAMESPACE=${val}
      [[ ${#} -gt 0 && ${1} != --* ]] && shift 1
      ;;
    --airflow-namespace)
      if [[ -z "${val}" ]]; then val=${2:-}; fi
      [[ -z "${val}" ]] && { err "--airflow-namespace requires a value"; usage; exit 1; }
      AIRFLOW_NAMESPACE=${val}
      [[ ${#} -gt 0 && ${1} != --* ]] && shift 1
      ;;
    --argo-values)
      if [[ -z "${val}" ]]; then val=${2:-}; fi
      [[ -z "${val}" ]] && { err "--argo-values requires a value"; usage; exit 1; }
      ARGO_VALUES=${val}
      [[ ${#} -gt 0 && ${1} != --* ]] && shift 1
      ;;
    --apps-path)
      if [[ -z "${val}" ]]; then val=${2:-}; fi
      [[ -z "${val}" ]] && { err "--apps-path requires a value"; usage; exit 1; }
      APPS_PATH=${val}
      [[ ${#} -gt 0 && ${1} != --* ]] && shift 1
      ;;
    -h|--help)
      usage; exit 0;
      ;;
    --*)
      err "Unknown argument: ${key}"; usage; exit 1;
      ;;
    *)
      # Positional argument not supported
      err "Unexpected positional argument: ${key}"; usage; exit 1;
      ;;
  esac
done

# Show effective configuration (flags override env defaults)
log "Config: cluster=${CLUSTER_NAME}, k8s=${K8S_VERSION}, kindCfg=${KIND_CONFIG:-<auto>}, argocdNs=${ARGOCD_NAMESPACE}, airflowNs=${AIRFLOW_NAMESPACE}, argoValues=${ARGO_VALUES}, appsPath=${APPS_PATH}"

# Dependency checks
require_cmd() { command -v "$1" >/dev/null 2>&1 || { err "'$1' is not installed"; exit 1; }; }
require_cmd kind
require_cmd kubectl
require_cmd helm

# Quick client version info (kubectl) for awareness; does not gate execution
KUBECTL_VER=$(kubectl version --client --short 2>/dev/null | sed -n 's/Client Version: //p')
log "kubectl client: ${KUBECTL_VER:-unknown}; Kind image target: kindest/node:${K8S_VERSION}"

# Prepare Kind config (either provided or generate minimal)
KIND_CFG_FILE="${KIND_CONFIG}"
if [[ -z "${KIND_CFG_FILE}" ]]; then
  KIND_CFG_FILE="/tmp/${CLUSTER_NAME}-kind.yaml"
  cat > "${KIND_CFG_FILE}" <<EOF
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
fi

# Create Kind cluster if not exists
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  log "Creating Kind cluster '${CLUSTER_NAME}' (image kindest/node:${K8S_VERSION})"
  kind create cluster --name "${CLUSTER_NAME}" --config "${KIND_CFG_FILE}" --image "kindest/node:${K8S_VERSION}"
else
  log "Kind cluster '${CLUSTER_NAME}' already exists"
fi

# Ensure kube context is working
kubectl cluster-info >/dev/null

# Create namespaces if missing
kubectl get ns "${ARGOCD_NAMESPACE}" >/dev/null 2>&1 || kubectl create ns "${ARGOCD_NAMESPACE}"
kubectl get ns "${AIRFLOW_NAMESPACE}" >/dev/null 2>&1 || kubectl create ns "${AIRFLOW_NAMESPACE}"

# Add/update Helm repos
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo add apache-airflow https://airflow.apache.org >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1 || true

# Install/upgrade Argo CD
log "Installing Argo CD (helm upgrade --install)"
helm upgrade --install argocd argo/argo-cd \
  --namespace "${ARGOCD_NAMESPACE}" \
  --create-namespace \
  -f "${ARGO_VALUES}"

# Wait for Argo CD core components to be ready
kubectl -n "${ARGOCD_NAMESPACE}" rollout status deployment/argocd-server --timeout=180s || true
kubectl -n "${ARGOCD_NAMESPACE}" rollout status deployment/argocd-repo-server --timeout=180s || true
kubectl -n "${ARGOCD_NAMESPACE}" rollout status deployment/argocd-application-controller --timeout=180s || true

# Apply Argo CD App of Apps
if [[ -d "${APPS_PATH}" ]]; then
  log "Applying Argo CD App of Apps from '${APPS_PATH}'"
  kubectl apply -n "${ARGOCD_NAMESPACE}" -f "${APPS_PATH}/app-of-apps.yaml"
else
  err "Apps path '${APPS_PATH}' not found"
fi

# Optional: Start port-forward for Argo CD UI if not running
if ! pgrep -f "kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE}" >/dev/null; then
  log "Starting Argo CD UI port-forward https://localhost:8080"
  nohup kubectl -n "${ARGOCD_NAMESPACE}" port-forward svc/argocd-server 8080:443 >/tmp/argocd-port-forward.log 2>&1 &
fi

log "Lab start complete"
