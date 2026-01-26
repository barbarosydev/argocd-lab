# Deployment

## Methods

The deployment method is controlled by `LAB_DEPLOY_METHOD` in `.env`:

| Method               | Setting                    | Use Case                             |
|----------------------|----------------------------|--------------------------------------|
| **GitOps** (default) | `LAB_DEPLOY_METHOD=gitops` | Production-like, auto-syncs from Git |
| **Helm**             | `LAB_DEPLOY_METHOD=helm`   | Quick local testing                  |

All `deploy` tasks respect this setting automatically.

## PostgreSQL

Deploy PostgreSQL database independently.

### Deploy PostgreSQL

```bash
task postgres:deploy
```

This will:

1. Generate secrets with random passwords
2. Deploy PostgreSQL (via ArgoCD if gitops, or Helm if helm)
3. Wait for PostgreSQL to be ready

### View Credentials

```bash
task postgres:password
```

### Check Status

```bash
task postgres:status
```

### Open psql Shell

```bash
task postgres:shell
```

### Undeploy

```bash
task postgres:undeploy
```

## Airflow with External PostgreSQL

Deploy Apache Airflow with external PostgreSQL database. **Requires PostgreSQL to be deployed first.**

### Components

- **PostgreSQL**: Bitnami chart (PostgreSQL 17.x) - deployed separately
- **Airflow**: Official chart 1.18.0 (Airflow 3.0.2)
- **Executor**: CeleryExecutor with Redis backend

Versions are configured in `.env` file:

```bash
LAB_AIRFLOW_HELM_VERSION=1.18.0
LAB_AIRFLOW_VERSION=3.0.2
LAB_POSTGRES_HELM_VERSION=16.7.15
LAB_POSTGRES_VERSION=17.5.0
```

### Deploy Airflow

First deploy PostgreSQL, then Airflow:

```bash
task postgres:deploy    # Deploy PostgreSQL first
task airflow:deploy     # Then deploy Airflow
```

The Airflow deployment will:

1. Check that PostgreSQL is running and ready
2. Generate Airflow webserver secret (if not exists)
3. Deploy Airflow via ArgoCD
4. Wait for Airflow webserver to be ready

### Access UI

```bash
task airflow:ui
```

Opens port-forward to Airflow webserver at <http://localhost:8080>

Credentials are displayed in the terminal output.

- Username: `admin`
- Password: (randomly generated - run `task airflow:passwords` to view)

### View Airflow Credentials

```bash
task airflow:passwords
```

Shows all credentials including PostgreSQL admin and Airflow database passwords.

### Check Airflow Status

```bash
task airflow:status
```

### Undeploy Airflow

Undeploy Airflow (PostgreSQL remains intact):

```bash
task airflow:undeploy
```

Undeploy PostgreSQL separately:

```bash
task postgres:undeploy
```

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
