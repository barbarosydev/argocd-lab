# Task Reference

## Environment

```bash
task env:start          # Start Minikube cluster
task env:start:verbose  # Start with debug output
task env:stop           # Stop and delete cluster
```

## Deployment

```bash
task deploy:argocd      # Install Argo CD
task deploy:apps        # Deploy all applications
```

## Lab

```bash
task lab:start          # Complete setup
task lab:stop           # Stop everything
```

## Documentation

```bash
task docs:serve         # Serve with live reload
task docs:build         # Build static site
task docs:clean         # Clean build artifacts
```

## Development

```bash
task install            # Install tools (macOS)
task pre-commit:run     # Run code quality checks
task pre-commit:install # Install git hooks
```

## Port Forwarding

Argo CD UI is automatically port-forwarded to localhost:8080 by `task lab:start`.

For other apps:

```bash
# Airflow
kubectl -n airflow port-forward svc/airflow-webserver 8081:8080

# Backend
kubectl port-forward svc/backend-service 8000:80
```
