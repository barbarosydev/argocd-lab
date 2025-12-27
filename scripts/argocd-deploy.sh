#!/usr/bin/env bash
set -euo pipefail

# argocd-deploy.sh: install/upgrade Argo CD and apply Argo CD apps (including airflow/backend)
# Usage:
#   scripts/argocd-deploy.sh --argocd-namespace argocd --airflow-namespace airflow --argo-values k8s/argocd/values.yaml --apps-path argocd/apps

ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-argocd}
AIRFLOW_NAMESPACE=${AIRFLOW_NAMESPACE:-airflow}
ARGO_VALUES=${ARGO_VALUES:-k8s/argocd/values.yaml}
APPS_PATH=${APPS_PATH:-argocd/apps}
VERBOSE=${LAB_VERBOSE:-0}

log() { echo "[argocd-deploy] $1"; }
err() { echo "[argocd-deploy] ERROR: $1" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --argocd-namespace)
      ARGOCD_NAMESPACE=${2:-}; [[ -z "$ARGOCD_NAMESPACE" ]] && { err "--argocd-namespace requires a value"; exit 1; }; shift 2;
      ;;
    --airflow-namespace)
      AIRFLOW_NAMESPACE=${2:-}; [[ -z "$AIRFLOW_NAMESPACE" ]] && { err "--airflow-namespace requires a value"; exit 1; }; shift 2;
      ;;
    --argo-values)
      ARGO_VALUES=${2:-}; [[ -z "$ARGO_VALUES" ]] && { err "--argo-values requires a value"; exit 1; }; shift 2;
      ;;
    --apps-path)
      APPS_PATH=${2:-}; [[ -z "$APPS_PATH" ]] && { err "--apps-path requires a value"; exit 1; }; shift 2;
      ;;
    --verbose)
      VERBOSE=1; shift 1;
      ;;
    -h|--help)
      echo "Usage: $0 [--argocd-namespace NAME] [--airflow-namespace NAME] [--argo-values PATH] [--apps-path PATH] [--verbose]"; exit 0;
      ;;
    *)
      err "Unknown arg: $1"; exit 1;
      ;;
  esac
done

if [[ ${VERBOSE} -eq 1 ]]; then
  set -x
  exec 3>&1 4>&2
else
  exec 3>/dev/null 4>/dev/null
fi

log "Checking required commands: kubectl, helm"
for cmd in kubectl helm; do
  command -v "$cmd" >/dev/null 2>&1 || { err "'$cmd' is not installed"; exit 1; }
done

log "Ensuring namespaces: ${ARGOCD_NAMESPACE}, ${AIRFLOW_NAMESPACE}"
kubectl get ns "$ARGOCD_NAMESPACE" >&3 2>&4 || kubectl create ns "$ARGOCD_NAMESPACE" >&3 2>&4
kubectl get ns "$AIRFLOW_NAMESPACE" >&3 2>&4 || kubectl create ns "$AIRFLOW_NAMESPACE" >&3 2>&4

log "Setting up Helm repositories (argo, apache-airflow)"
helm repo add argo https://argoproj.github.io/argo-helm >&3 2>&4 || true
helm repo add apache-airflow https://airflow.apache.org >&3 2>&4 || true
helm repo update >&3 2>&4 || true

log "Installing Argo CD via Helm"
helm upgrade --install argocd argo/argo-cd \
  --namespace "$ARGOCD_NAMESPACE" \
  --create-namespace \
  -f "$ARGO_VALUES" >&3 2>&4

log "Waiting for Argo CD deployments to be ready (best-effort)"
kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-server --timeout=180s >&3 2>&4 || true
kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-repo-server --timeout=180s >&3 2>&4 || true
kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-application-controller --timeout=180s >&3 2>&4 || true

if [[ -d "$APPS_PATH" ]]; then
  log "Applying App of Apps from '$APPS_PATH/app-of-apps.yaml'"
  kubectl apply -n "$ARGOCD_NAMESPACE" -f "$APPS_PATH/app-of-apps.yaml" >&3 2>&4
else
  err "Apps path '$APPS_PATH' not found"; exit 1;
fi

log "Deployments applied"
