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

## Argo CD Not Deploying

**Check Argo CD Pods**:

```bash
kubectl get pods -n argocd
```

**Check Argo CD Server Logs**:

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=100
```

**Check Argo CD Service**:

```bash
kubectl get svc -n argocd
```

**Reinstall Argo CD**:

```bash
helm uninstall argocd -n argocd
task argocd:deploy
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

## Repository Authentication Errors

**Error**: `Failed to load target state: authentication required: Repository not found`

This error occurs when trying to access a private GitHub repository without credentials.

**Solution**:

1. Create a GitHub Personal Access Token (PAT) with `repo` scope
2. Set the environment variable:

   ```bash
   export GITHUB_PAT=ghp_your_token_here
   ```

3. Redeploy ArgoCD:

   ```bash
   task argocd:deploy
   ```

See the **[Private Repository Access](private-repository.md)** guide for detailed instructions.

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
