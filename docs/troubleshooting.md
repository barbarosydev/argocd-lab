# Troubleshooting

## Minikube Won't Start

**Check Docker**:

```bash
docker ps
```

If Docker isn't running, start Docker Desktop.

**Recreate Cluster**:

```bash
task lab:stop
task env:start
```

## Argo CD Apps Not Syncing

**Check Status**:

```bash
kubectl get applications -n argocd
```

**View Logs**:

```bash
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-application-controller
```

**Force Sync**:

```bash
kubectl patch application <app-name> -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

## Port Already in Use

**Kill Port-Forward**:

```bash
pkill -f "kubectl port-forward svc/argocd-server"
```

## Pods Not Starting

**Check Status**:

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Common Issues**:

- Image pull errors → Check Docker Desktop
- Resource constraints → Increase Minikube memory
- PVC issues → Check storage provisioner

## Pre-commit Hooks Failing

**Update Hooks**:

```bash
pre-commit clean
pre-commit install-hooks
```

**Run Specific Hook**:

```bash
pre-commit run <hook-id> --all-files
```
