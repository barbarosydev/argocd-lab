# Deployment

## Methods

The deployment method is controlled by `LAB_DEPLOY_METHOD` in `.env`:

| Method               | Setting                    | Use Case                             |
|----------------------|----------------------------|--------------------------------------|
| **GitOps** (default) | `LAB_DEPLOY_METHOD=gitops` | Production-like, auto-syncs from Git |
| **Helm**             | `LAB_DEPLOY_METHOD=helm`   | Quick local testing                  |

All `deploy` tasks respect this setting automatically.

## Demo App

### Deploy Demo App

```bash
task apps:deploy                      # GitOps (default)
task apps:deploy -- --method helm     # Direct Helm
```

### Undeploy Demo App

```bash
task apps:undeploy                    # GitOps
task apps:undeploy -- --method helm   # Helm
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
