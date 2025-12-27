#!/usr/bin/env bash
set -euo pipefail

# argocd-deploy.sh: install/upgrade Argo CD on Minikube
# Usage:
#   scripts/argocd-deploy.sh --argocd-namespace argocd --argo-values k8s/argocd/values.yaml --port 8081

ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-argocd}
ARGO_VALUES=${ARGO_VALUES:-k8s/argocd/values.yaml}
ARGOCD_PORT=${ARGOCD_PORT:-8081}
VERBOSE=${LAB_VERBOSE:-0}

log() { echo "[argocd-deploy] $1"; }
err() { echo "[argocd-deploy] ERROR: $1" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --argocd-namespace)
      ARGOCD_NAMESPACE=${2:-}
      [[ -z "$ARGOCD_NAMESPACE" ]] && { err "--argocd-namespace requires a value"; exit 1; }
      shift 2
      ;;
    --argo-values)
      ARGO_VALUES=${2:-}
      [[ -z "$ARGO_VALUES" ]] && { err "--argo-values requires a value"; exit 1; }
      shift 2
      ;;
    --port)
      ARGOCD_PORT=${2:-}
      [[ -z "$ARGOCD_PORT" ]] && { err "--port requires a value"; exit 1; }
      shift 2
      ;;
    --verbose)
      VERBOSE=1
      shift 1
      ;;
    -h|--help)
      echo "Usage: $0 [--argocd-namespace NAME] [--argo-values PATH] [--port PORT] [--verbose]"
      exit 0
      ;;
    *)
      err "Unknown arg: $1"
      exit 1
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

log "Ensuring namespace: ${ARGOCD_NAMESPACE}"
kubectl get ns "$ARGOCD_NAMESPACE" >&3 2>&4 || kubectl create ns "$ARGOCD_NAMESPACE" >&3 2>&4

log "Setting up Helm repository for Argo CD"
helm repo add argo https://argoproj.github.io/argo-helm >&3 2>&4 || true
helm repo update >&3 2>&4 || true

log "Installing Argo CD via Helm"
helm upgrade --install argocd argo/argo-cd \
  --namespace "$ARGOCD_NAMESPACE" \
  --create-namespace \
  -f "$ARGO_VALUES" >&3 2>&4

log "Waiting for Argo CD deployments to be ready"
kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-server --timeout=180s >&3 2>&4 || true
kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-repo-server --timeout=180s >&3 2>&4 || true
kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-application-controller --timeout=180s >&3 2>&4 || true

log "Starting Argo CD UI port-forward"

# Check if port is already in use
if lsof -Pi :"${ARGOCD_PORT}" -sTCP:LISTEN -t >/dev/null 2>&1 ; then
  log "WARNING: Port ${ARGOCD_PORT} is already in use"
  log "Killing existing port-forward processes..."
  pkill -f "kubectl port-forward svc/argocd-server" || true
  sleep 2
fi

# Start port-forward
log "Port-forwarding Argo CD UI to https://localhost:${ARGOCD_PORT}"
nohup kubectl -n "${ARGOCD_NAMESPACE}" port-forward svc/argocd-server "${ARGOCD_PORT}":443 \
  >/tmp/argocd-port-forward.log 2>&1 &
PORT_FORWARD_PID=$!

# Wait a bit and check if port-forward is successful
sleep 3
if ps -p $PORT_FORWARD_PID > /dev/null 2>&1; then
  log "✓ Port-forward started successfully (PID: $PORT_FORWARD_PID)"
else
  err "Port-forward failed to start. Check /tmp/argocd-port-forward.log"
  cat /tmp/argocd-port-forward.log
  exit 1
fi

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "✓ Argo CD deployment complete!"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log ""
log "  Access Argo CD UI: http://localhost:${ARGOCD_PORT}"
log ""
log "  Get admin password:"
log "  kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode && echo"
log ""
log "  Or use: task argocd:password"
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
