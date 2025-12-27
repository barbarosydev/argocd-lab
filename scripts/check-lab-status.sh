#!/usr/bin/env bash
# check-lab-status.sh: Check the status of the lab environment

echo "=== Argo CD Lab Status Check ==="
echo ""

# Check Minikube
echo "1. Minikube Status:"
if minikube status -p argocd-lab >/dev/null 2>&1; then
  minikube status -p argocd-lab
else
  echo "  ✗ Minikube cluster 'argocd-lab' is not running"
  echo "  Run: task lab:start"
fi
echo ""

# Check kubectl context
echo "2. Kubectl Context:"
kubectl config current-context 2>/dev/null || echo "  ✗ No kubectl context set"
echo ""

# Check Argo CD namespace
echo "3. Argo CD Namespace:"
if kubectl get namespace argocd >/dev/null 2>&1; then
  echo "  ✓ Namespace 'argocd' exists"
else
  echo "  ✗ Namespace 'argocd' not found"
fi
echo ""

# Check Argo CD pods
echo "4. Argo CD Pods:"
if kubectl get pods -n argocd >/dev/null 2>&1; then
  kubectl get pods -n argocd
else
  echo "  ✗ Cannot get Argo CD pods"
fi
echo ""

# Check Argo CD service
echo "5. Argo CD Service:"
if kubectl get svc -n argocd argocd-server >/dev/null 2>&1; then
  kubectl get svc -n argocd argocd-server
else
  echo "  ✗ Argo CD service not found"
fi
echo ""

# Check port-forward
echo "6. Port-Forward Status:"
if pgrep -f "kubectl port-forward svc/argocd-server" >/dev/null; then
  echo "  ✓ Port-forward is running"
  pgrep -f "kubectl port-forward svc/argocd-server" -l
else
  echo "  ✗ Port-forward is not running"
  echo "  Run: task argocd:deploy"
fi
echo ""

# Check port availability
echo "7. Port 8081 Status:"
if lsof -Pi :8081 -sTCP:LISTEN -t >/dev/null 2>&1; then
  echo "  Process using port 8081:"
  lsof -i :8081
else
  echo "  ✓ Port 8081 is available"
fi
echo ""

# Check port-forward logs
echo "8. Port-Forward Logs:"
if [[ -f /tmp/argocd-port-forward.log ]]; then
  echo "  Last 10 lines of /tmp/argocd-port-forward.log:"
  tail -10 /tmp/argocd-port-forward.log
else
  echo "  ✗ No port-forward log found"
fi
echo ""

echo "=== Status Check Complete ==="
