# Deployment

## Methods

| Method               | Command                                   | Use Case                             |
|----------------------|-------------------------------------------|--------------------------------------|
| **GitOps** (default) | `task argocd:deploy-app`                  | Production-like, auto-syncs from Git |
| **Helm**             | `task argocd:deploy-app -- --method helm` | Quick local testing                  |

## Airflow with External PostgreSQL

Deploy Apache Airflow with external PostgreSQL database via ArgoCD.

### Components

- **PostgreSQL**: Bitnami chart 16.5.0 (PostgreSQL 16.x)
- **Airflow**: Official chart 1.18.0 (Airflow 3.0.2)
- **Executor**: CeleryExecutor with Redis backend

### Deploy

```bash
task airflow:deploy
```

This will:

1. Generate PostgreSQL secrets (random passwords)
2. Deploy PostgreSQL via ArgoCD
3. Wait for PostgreSQL to be ready
4. Deploy Airflow via ArgoCD
5. Wait for Airflow webserver to be ready

### Access UI

```bash
task airflow:ui
```

Opens port-forward to Airflow webserver at <http://localhost:8080>

Default credentials:

- Username: `admin`
- Password: `admin`

### View Credentials

```bash
task airflow:passwords
```

Shows all credentials including PostgreSQL admin and Airflow database passwords.

### Check Status

```bash
task airflow:status
```

### Undeploy

```bash
task airflow:undeploy
```

This removes both Airflow and PostgreSQL applications and deletes secrets.

To keep secrets for redeployment:

```bash
./scripts/airflow-undeploy.sh --keep-secrets
```

## Demo App

### Deploy Demo App

```bash
task argocd:deploy-app                      # GitOps (default)
task argocd:deploy-app -- --method helm     # Direct Helm
```

### Undeploy Demo App

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
