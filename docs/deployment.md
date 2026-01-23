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

## Apache Airflow 3

Production-like Airflow 3 deployment using the official Apache Airflow Helm chart.

### Prerequisites

Airflow requires more resources. Update your `.env` file:

```bash
LAB_MINIKUBE_CPUS=8
LAB_MINIKUBE_MEMORY=16384
LAB_MINIKUBE_DISK_SIZE=30g
```

If you have an existing cluster, delete and recreate it:

```bash
task lab:nuke
task lab:up
```

### Architecture

The deployment includes:

- **Webserver** - Airflow UI (port 8080)
- **Scheduler** - DAG scheduling
- **PostgreSQL** - Metadata database (deployed separately via Argo CD)

Notes:

- This lab disables the chart's bundled PostgreSQL and deploys a small Postgres Deployment in `k8s/airflow/`.
- PgBouncer is disabled to keep the setup minimal.

### Deploy Airflow

```bash
task airflow:deploy
```

Deployment takes 3-5 minutes. Monitor progress:

```bash
task airflow:status
```

### Access UI

```bash
task airflow:ui
```

Opens port-forward to `http://localhost:8080`

Default credentials:

- **Username:** admin
- **Password:** `task airflow:password`

### Useful Commands

```bash
task airflow:status       # Check deployment status
task airflow:logs         # View scheduler logs
task airflow:shell        # Open shell in scheduler pod
task airflow:sync         # Force ArgoCD sync
task airflow:password     # Show Airflow admin password
task airflow:db-password  # Show DB connection string from secret
task airflow:undeploy     # Remove Airflow
```

### Configuration

Custom values are in `k8s/airflow/values.yaml`. Key settings:

| Setting                          | Default       | Description                      |
|----------------------------------|---------------|----------------------------------|
| `executor`                       | LocalExecutor | Simple executor for this lab     |
| `webserver.defaultUser.password` | admin         | Change for production            |
| `dags.gitSync.enabled`           | false         | Enable for DAG syncing           |
| `postgresql.enabled`             | false         | Bundled PostgreSQL is disabled   |
| `pgbouncer.enabled`              | false         | Connection pooling is disabled   |

### Adding DAGs

1. **Local development:** Copy DAGs to the scheduler pod
2. **GitSync (recommended):** Enable `dags.gitSync` in values.yaml

To enable GitSync, edit `k8s/airflow/values.yaml`:

```yaml
dags:
  gitSync:
    enabled: true
    repo: https://github.com/your-org/airflow-dags.git
    branch: main
    subPath: "dags"
```

### Resource Requirements

| Component     | CPU Request | Memory Request |
|---------------|-------------|----------------|
| Webserver     | 200m        | 512Mi          |
| Scheduler     | 200m        | 512Mi          |
| Triggerer     | 100m        | 256Mi          |
| DAG Processor | 100m        | 256Mi          |
| PostgreSQL    | 100m        | 256Mi          |
| Worker Pods   | 100m        | 256Mi          |

**Total minimum:** ~1 CPU, 2GB RAM
**Recommended:** 4+ CPUs, 8GB+ RAM
