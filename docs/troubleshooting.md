# Troubleshooting

## Minikube Won't Start

```bash
docker ps                 # Check Docker is running
task nuke && task up      # Recreate cluster
```

## Argo CD Issues

```bash
kubectl get pods -n argocd                    # Check pods
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50

# Reinstall
helm uninstall argocd -n argocd
task argocd:bootstrap
```

## Apps Not Syncing

```bash
kubectl get applications -n argocd
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-application-controller --tail=50
```

## Auth Errors (Private Repos)

```bash
export GITHUB_PAT=ghp_your_token_here
task argocd:bootstrap
```

See [Private Repository Access](private-repository.md).

## Port Already in Use

```bash
pkill -f "kubectl port-forward svc/argocd-server"
```

## Pods Not Starting

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
```

Common causes: Docker not running, resource limits, image pull errors.
