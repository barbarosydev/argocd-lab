#!/usr/bin/env bash
set -euo pipefail

# lab-start.sh: start local lab with Minikube + Argo CD + Helm
# Usage:
#   scripts/lab-start.sh \
#     --profile argocd-lab \
#     --k8s-version v1.35.0 \
#     --argocd-namespace argocd \
#     --airflow-namespace airflow \
#     --argo-values ./k8s/argocd/values.yaml \
#     --apps-path ./argocd/apps
# All flags are optional. Defaults are sensible for local dev.

# Defaults
PROFILE=${MINIKUBE_PROFILE:-${CLUSTER_NAME:-argocd-lab}}
K8S_VERSION=${K8S_VERSION:-v1.35.0}
ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-argocd}
AIRFLOW_NAMESPACE=${AIRFLOW_NAMESPACE:-airflow}
ARGO_VALUES=${ARGO_VALUES:-k8s/argocd/values.yaml}
APPS_PATH=${APPS_PATH:-argocd/apps}
VERBOSE=${LAB_VERBOSE:-0}

log() { echo "[lab-start] $1"; }
err() { echo "[lab-start] ERROR: $1" >&2; }

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --profile NAME              Minikube profile name (default: ${PROFILE})
  --cluster-name NAME         Alias for --profile (backward-compatible)
  --k8s-version VERSION       Kubernetes version for Minikube (default: ${K8S_VERSION})
  --argocd-namespace NAME     Namespace for Argo CD (default: ${ARGOCD_NAMESPACE})
  --airflow-namespace NAME    Namespace for Airflow (default: ${AIRFLOW_NAMESPACE})
  --argo-values PATH          Helm values for Argo CD install (default: ${ARGO_VALUES})
  --apps-path PATH            Path for Argo CD apps (App of Apps) (default: ${APPS_PATH})
  --verbose                   Print each command as it executes and show full outputs
  -h, --help                  Show this help

Environment overrides supported: MINIKUBE_PROFILE, K8S_VERSION, ARGOCD_NAMESPACE, AIRFLOW_NAMESPACE, ARGO_VALUES, APPS_PATH.
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
  else
    # Handle case where value is the next argument
    case "${key}" in
      --profile|--cluster-name|--k8s-version|--argocd-namespace|--airflow-namespace|--argo-values|--apps-path)
        if [[ ${2:-} && ${2} != --* ]]; then
          val=${2}
          shift 2
        else
          shift 1
        fi
        ;;
      *)
        shift 1
        ;;
    esac
  fi

  case "${key}" in
    --verbose)
      VERBOSE=1
      ;;
    --profile|--cluster-name)
      [[ -z "${val}" ]] && { err "${key} requires a value"; usage; exit 1; }
      PROFILE=${val}
      ;;
    --k8s-version)
      [[ -z "${val}" ]] && { err "--k8s-version requires a value"; usage; exit 1; }
      K8S_VERSION=${val}
      ;;
    --argocd-namespace)
      [[ -z "${val}" ]] && { err "--argocd-namespace requires a value"; usage; exit 1; }
      ARGOCD_NAMESPACE=${val}
      ;;
    --airflow-namespace)
      [[ -z "${val}" ]] && { err "--airflow-namespace requires a value"; usage; exit 1; }
      AIRFLOW_NAMESPACE=${val}
      ;;
    --argo-values)
      [[ -z "${val}" ]] && { err "--argo-values requires a value"; usage; exit 1; }
      ARGO_VALUES=${val}
      ;;
    --apps-path)
      [[ -z "${val}" ]] && { err "--apps-path requires a value"; usage; exit 1; }
      APPS_PATH=${val}
      ;;
    -h|--help)
      usage; exit 0;
      ;;
    --*)
      err "Unknown argument: ${key}"; usage; exit 1;
      ;;
    *)
      err "Unexpected positional argument: ${key}"; usage; exit 1;
      ;;
  esac
done

# Redirection logic of command outputs based on --verbose flag
if [[ ${VERBOSE} -eq 1 ]]; then
  log "Verbose mode enabled (LAB_VERBOSE=${LAB_VERBOSE:-})"
  set -x
  exec 3>&1 4>&2
else
  exec 3>/dev/null 4>/dev/null
fi

log "Starting lab setup"
# Show effective configuration (flags override env defaults)
log "Config: profile=${PROFILE}, k8s=${K8S_VERSION}, argocdNs=${ARGOCD_NAMESPACE}, airflowNs=${AIRFLOW_NAMESPACE}, argoValues=${ARGO_VALUES}, appsPath=${APPS_PATH}"

# Dependency checks
log "Checking required commands: minikube, kubectl, helm, jq"
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "'$1' is not installed"; exit 1; }
}
require_cmd minikube
require_cmd kubectl
require_cmd helm
require_cmd jq

# Quick client version info (kubectl)
KUBECTL_VER=$(kubectl version --client -o=json 2>/dev/null | jq -r '.clientVersion.gitVersion' 2>/dev/null)
log "kubectl client: ${KUBECTL_VER:-unknown}"

# Start or ensure Minikube profile
if ! minikube profile list -o json 2>/dev/null | jq -e --arg p "$PROFILE" '.valid[]?.Name == $p' >/dev/null; then
  log "Creating Minikube profile '${PROFILE}' (k8s ${K8S_VERSION})"
  minikube start -p "${PROFILE}" --kubernetes-version="${K8S_VERSION}" >&3 2>&4
else
  log "Minikube profile '${PROFILE}' already exists"
  # Ensure it's running
  minikube -p "${PROFILE}" status >&3 2>&4 || minikube start -p "${PROFILE}" --kubernetes-version="${K8S_VERSION}" >&3 2>&4
fi

# Ensure kubectl context for this profile
log "Setting kubectl context to Minikube profile '${PROFILE}'"
minikube -p "${PROFILE}" update-context >&3 2>&4

# Ensure cluster responds
log "Validating Kubernetes context"
kubectl cluster-info >&3 2>&4

log "Ensuring namespaces: ${ARGOCD_NAMESPACE}, ${AIRFLOW_NAMESPACE}"
kubectl get ns "${ARGOCD_NAMESPACE}" >&3 2>&4 || kubectl create ns "${ARGOCD_NAMESPACE}" >&3 2>&4
kubectl get ns "${AIRFLOW_NAMESPACE}" >&3 2>&4 || kubectl create ns "${AIRFLOW_NAMESPACE}" >&3 2>&4

log "Setting up Helm repositories (argo, apache-airflow)"
helm repo add argo https://argoproj.github.io/argo-helm >&3 2>&4 || true
helm repo add apache-airflow https://airflow.apache.org >&3 2>&4 || true
helm repo update >&3 2>&4 || true

# Install/upgrade Argo CD
log "Installing Argo CD via Helm"
helm upgrade --install argocd argo/argo-cd \
  --namespace "${ARGOCD_NAMESPACE}" \
  --create-namespace \
  -f "${ARGO_VALUES}" >&3 2>&4

# Wait for Argo CD core components to be ready
log "Waiting for Argo CD deployments to be ready"
kubectl -n "${ARGOCD_NAMESPACE}" rollout status deployment/argocd-server --timeout=180s >&3 2>&4 || true
kubectl -n "${ARGOCD_NAMESPACE}" rollout status deployment/argocd-repo-server --timeout=180s >&3 2>&4 || true
kubectl -n "${ARGOCD_NAMESPACE}" rollout status deployment/argocd-application-controller --timeout=180s >&3 2>&4 || true

# Apply Argo CD App of Apps
if [[ -d "${APPS_PATH}" ]]; then
  log "Applying App of Apps from '${APPS_PATH}/app-of-apps.yaml'"
  kubectl apply -n "${ARGOCD_NAMESPACE}" -f "${APPS_PATH}/app-of-apps.yaml" >&3 2>&4
else
  err "Apps path '${APPS_PATH}' not found"
fi

# Optional: Start port-forward for Argo CD UI if not running
log "Ensuring Argo CD UI port-forward"
if ! pgrep -f "kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE}" >/dev/null; then
  log "Starting port-forward to https://localhost:8080"
  nohup kubectl -n "${ARGOCD_NAMESPACE}" port-forward svc/argocd-server 8080:443 >/tmp/argocd-port-forward.log 2>&1 &
fi

log "Lab start complete"
