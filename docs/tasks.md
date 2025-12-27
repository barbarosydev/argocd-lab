# Task Reference

## Lab

```bash
task lab:start          # Start Minikube + Argo CD
task lab:stop           # Stop everything
```

## Environment

```bash
task env:start          # Start Minikube and deploy Argo CD
task env:start:verbose  # Start with debug output
task env:stop           # Stop and delete cluster
```

## Argo CD

```bash
task argocd:deploy      # Deploy Argo CD (if already on Minikube)
task argocd:password    # Get admin password
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

## Accessing Argo CD

Argo CD UI is automatically port-forwarded to <https://localhost:8081> by `task lab:start`.

Get admin password:

```bash
task argocd:password
```

Login:

- URL: <https://localhost:8081>
- Username: admin
- Password: (from command above)
