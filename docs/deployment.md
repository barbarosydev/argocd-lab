# Deployment

## Methods

| Method               | Command                                   | Use Case                             |
|----------------------|-------------------------------------------|--------------------------------------|
| **GitOps** (default) | `task argocd:deploy-app`                  | Production-like, auto-syncs from Git |
| **Helm**             | `task argocd:deploy-app -- --method helm` | Quick local testing                  |

## Demo App

### Deploy

```bash
task argocd:deploy-app                      # GitOps (default)
task argocd:deploy-app -- --method helm     # Direct Helm
```

### Undeploy

```bash
task argocd:undeploy-app                    # GitOps
task argocd:undeploy-app -- --method helm   # Helm
```

### Test

```bash
kubectl port-forward svc/demo-api 8080:80

# In another terminal
curl http://localhost:8080/health
curl http://localhost:8080/ping
```
