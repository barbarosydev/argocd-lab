# Welcome

A local Kubernetes lab for learning GitOps with Argo CD, Helm, and Minikube.

## What's Included

- **Minikube** - Local Kubernetes cluster (v1.35.0)
- **Argo CD** - GitOps continuous delivery
- **Helm** - Package manager
- **Applications** - Airflow and Python backend examples

## Quick Links

- **[Setup](setup.md)** - Installation and configuration
- **[Tasks](tasks.md)** - Common commands
- **[Troubleshooting](troubleshooting.md)** - Common issues

## Getting Started

```bash
task install    # Install tools
task lab:start  # Start everything
```

Access Argo CD UI at <https://localhost:8080>

## Architecture

```text
Minikube → Argo CD → Applications (Airflow, Backend)
```

Argo CD watches `k8s/` directory and auto-syncs changes to the cluster.

## Learn More

- Modify `k8s/*/values.yaml` to change app configs
- Add new apps in `argocd/apps/`
- Use `task -l` to see all commands
