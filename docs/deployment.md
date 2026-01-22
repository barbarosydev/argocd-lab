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
# Port-forward the service (runs in foreground)
kubectl port-forward svc/demo-api 8080:8000

# In another terminal, test the endpoints
curl http://localhost:8080/health
curl http://localhost:8080/ping
curl http://localhost:8080/info
```
