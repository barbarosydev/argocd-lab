#!/usr/bin/env bash
# Quick test script to verify lab setup

echo "=== Testing Argo CD Lab Setup ==="
echo ""

echo "1. Checking required commands..."
for cmd in kubectl helm minikube; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  ✓ $cmd installed"
  else
    echo "  ✗ $cmd NOT installed"
  fi
done

echo ""
echo "2. Checking Taskfile..."
if [[ -f "Taskfile.yml" ]]; then
  echo "  ✓ Taskfile.yml exists"
else
  echo "  ✗ Taskfile.yml missing"
fi

echo ""
echo "3. Checking scripts..."
for script in minikube-start.sh argocd-deploy.sh minikube-stop.sh setup-dependencies.sh; do
  if [[ -x "scripts/$script" ]]; then
    echo "  ✓ scripts/$script executable"
  elif [[ -f "scripts/$script" ]]; then
    echo "  ⚠ scripts/$script exists but not executable (run: chmod +x scripts/$script)"
  else
    echo "  ✗ scripts/$script missing"
  fi
done

echo ""
echo "4. Checking Argo CD values..."
if [[ -f "k8s/argocd/values.yaml" ]]; then
  echo "  ✓ k8s/argocd/values.yaml exists"
else
  echo "  ✗ k8s/argocd/values.yaml missing"
fi

echo ""
echo "=== Test Complete ==="
echo ""
echo "To start the lab, run: task lab:start"
