# Deployment

## Methods

| Method               | Command                                | Use Case                             |
|----------------------|----------------------------------------|--------------------------------------|
| **GitOps** (default) | `task apps:deploy`                     | Production-like, auto-syncs from Git |
| **Helm**             | `task apps:deploy -- --method helm`    | Quick local testing                  |

## Airflow with External PostgreSQL

Deploy Apache Airflow with external PostgreSQL database via ArgoCD.

### Components

- **PostgreSQL**: Bitnami chart (PostgreSQL 17.x)
- **Airflow**: Official chart 1.18.0 (Airflow 3.0.2)
- **Executor**: CeleryExecutor with Redis backend

Versions are configured in `.env` file:

```bash
LAB_AIRFLOW_HELM_VERSION=1.18.0
LAB_AIRFLOW_VERSION=3.0.2
LAB_POSTGRES_HELM_VERSION=17.4.3
LAB_POSTGRES_VERSION=17
```

### Deploy

```bash
task airflow:deploy
```

This will:

1. Generate secrets with random passwords (PostgreSQL admin, Airflow DB user, Airflow webserver admin)
2. Deploy PostgreSQL via ArgoCD
3. Wait for PostgreSQL to be ready
4. Deploy Airflow via ArgoCD
5. Wait for Airflow webserver to be ready

### Access UI

```bash
task airflow:ui
```

Opens port-forward to Airflow webserver at <http://localhost:8080>

Credentials are displayed in the terminal output.

- Username: `admin`
- Password: (randomly generated - run `task airflow:passwords` to view)

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
./scripts/airflow.sh undeploy --keep-secrets
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
