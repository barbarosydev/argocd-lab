# Application Deployment Guide

This guide explains how to deploy applications in the ArgoCD Lab environment.

## Deployment Methods

The lab supports two deployment methods:

### GitOps Method (Default)

- Deploys via ArgoCD
- Continuous sync from Git
- Self-healing and automated rollback
- Best for production

### Helm Method

- Direct Helm deployment
- Quick testing and development
- No ArgoCD overhead
- Best for local development

## Demo API Application

The repository includes a demo FastAPI application (`demo-api`) that demonstrates:

- FastAPI web framework with async support
- Health check endpoints for Kubernetes probes
- Docker containerization using `uv` package manager
- Comprehensive test suite with pytest
- Helm chart deployment
- ArgoCD GitOps integration

### Quick Deploy

```bash
# Deploy with GitOps (default - recommended)
task deploy

# Deploy via Helm (for testing)
task argocd:deploy-app -- --method helm

# Deploy to specific namespace
task argocd:deploy-app -- --namespace production
```

### Undeploy Applications

```bash
# Undeploy with GitOps (default)
task undeploy

# Undeploy via Helm
task argocd:undeploy-app -- --method helm
```

**Auto-Detection:** If you use the wrong method, the script will detect it and suggest the correct command.

### Available Endpoints

| Method | Path         | Description                    |
|--------|--------------|--------------------------------|
| GET    | `/health`    | Health check for K8s probes    |
| GET    | `/ping`      | Simple ping endpoint           |
| POST   | `/datetime`  | Returns current UTC datetime   |
| GET    | `/info`      | Application information        |

### Testing Locally

```bash
# Port-forward to the service
kubectl -n default port-forward svc/demo-api 8000:8000

# Test endpoints (in another terminal)
curl http://localhost:8000/health
curl http://localhost:8000/ping
curl -X POST http://localhost:8000/datetime
curl http://localhost:8000/info
```

### Running Tests

The application includes a comprehensive test suite:

```bash
cd k8s/demo-api/app

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install fastapi "uvicorn[standard]" pytest httpx

# Run tests
pytest -v

# Deactivate when done
deactivate
```

All tests validate the API endpoints and ensure proper functionality.

## Creating New Applications

The deployment system is generic and supports any application following this structure:

### Directory Structure

```text
k8s/<app-name>/
├── Chart.yaml              # Helm chart metadata
├── values.yaml             # Configuration values
├── app/
│   ├── Dockerfile         # Container definition
│   ├── pyproject.toml     # Dependencies (for Python apps)
│   └── main.py            # Application code
└── templates/
    ├── deployment.yaml    # Kubernetes Deployment
    └── service.yaml       # Kubernetes Service
```

### Deployment Steps

1. **Create Application Structure**

   ```bash
   mkdir -p k8s/my-app/{app,templates}
   ```

2. **Create Helm Chart**
   - Add `Chart.yaml` with metadata
   - Add `values.yaml` with configuration
   - Create templates for Deployment and Service

3. **Create ArgoCD Application** (optional)

   ```bash
   # Create ArgoCD manifest
   cat > argocd/apps/my-app.yaml << EOF
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: my-app
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/barbarosydev/argocd-lab.git
       targetRevision: HEAD
       path: k8s/my-app
       helm:
         valueFiles:
           - values.yaml
     destination:
       server: https://kubernetes.default.svc
       namespace: default
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
   EOF
   ```

4. **Deploy**

   ```bash
   # Direct Helm deployment (for local testing)
   task argocd:deploy-app APP_NAME=my-app

   # ArgoCD GitOps deployment
   task argocd:deploy-app APP_NAME=my-app -- --use-argocd
   ```

## Deployment Options

### Option 1: Direct Helm (Local Testing)

Best for local development and testing:

```bash
task argocd:deploy-app APP_NAME=demo-api
```

This will:

1. Build Docker image using Minikube's Docker daemon
2. Deploy directly via Helm to specified namespace
3. Create/update resources immediately

### Option 2: ArgoCD GitOps

Best for production-like workflows:

```bash
task argocd:deploy-app APP_NAME=demo-api -- --use-argocd
```

This will:

1. Build Docker image
2. Register application with ArgoCD
3. Let ArgoCD manage sync and deployment
4. Provide automatic sync on git changes (if configured)

## Configuration

### Image Settings

For local Minikube deployment, ensure `values.yaml` includes:

```yaml
image:
  repository: <app-name>
  tag: latest
  pullPolicy: Never  # Important for local images
```

### Resource Limits

Adjust resource limits in `values.yaml`:

```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 100m
    memory: 128Mi
```

### Health Checks

Configure probes in deployment template:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Troubleshooting

### Image Pull Errors

If you see `ImagePullBackOff` errors:

```bash
# Ensure Docker is using Minikube's daemon
eval $(minikube -p argocd-lab docker-env)

# Rebuild the image
docker build -t <app-name>:latest k8s/<app-name>/app

# Verify image exists
docker images | grep <app-name>
```

### Pod Not Starting

```bash
# Check pod status
kubectl -n default get pods -l app=<app-name>

# View pod details
kubectl -n default describe pod -l app=<app-name>

# Check logs
kubectl -n default logs -l app=<app-name> --follow
```

### ArgoCD Sync Issues

```bash
# Check application status
kubectl -n argocd get app <app-name>

# View application details
kubectl -n argocd describe app <app-name>

# Open ArgoCD UI
task argocd:ui
```

## Best Practices

1. **Use health endpoints** - Implement `/health` for liveness/readiness probes
2. **Pin dependency versions** - Specify exact versions in `pyproject.toml`
3. **Run tests locally** - Validate application before deploying
4. **Use appropriate resources** - Start small, scale as needed
5. **Leverage ArgoCD** - Use GitOps for production deployments
6. **Follow naming conventions** - Use kebab-case for application names
7. **Document endpoints** - Include API documentation in code

## Next Steps

- Explore the `demo-api` application code
- Create your own custom application
- Set up automatic ArgoCD sync
- Add monitoring and observability
- Implement CI/CD pipelines
