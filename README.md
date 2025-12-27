# Argo CD Lab

[![CI](https://github.com/barbarosydev/argocd-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/barbarosydev/argocd-lab/actions)

A local Kubernetes lab for learning GitOps with **Argo CD**, **Helm**, and **Minikube**.

## Quick Start

```bash
# Install dependencies (macOS)
task install

# Start everything
task lab:start

# Access Argo CD UI at https://localhost:8080
# Username: admin
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode
```

## Architecture

```text
Minikube Cluster
├── Argo CD (argocd namespace)
│   └── Manages all applications via App-of-Apps
└── Applications
    ├── Airflow (airflow namespace)
    └── Backend API (default namespace)
```

## Key Commands

| Command | Description |
|---------|-------------|
| `task install` | Install tools (macOS) |
| `task env:start` | Start Minikube |
| `task deploy:argocd` | Deploy Argo CD |
| `task deploy:apps` | Deploy applications |
| `task lab:start` | Full setup (env + apps) |
| `task lab:stop` | Stop and cleanup |
| `task docs:serve` | Serve documentation |

## Repository Structure

```text
.
├── argocd/apps/          # Argo CD Application manifests
├── docs/                 # Documentation
├── k8s/                  # Helm charts and values
│   ├── airflow/
│   ├── argocd/
│   └── backend/
├── scripts/              # Automation scripts
│   ├── minikube-start.sh
│   ├── minikube-stop.sh
│   ├── argocd-deploy.sh
│   └── setup-dependencies.sh
└── Taskfile.yml          # Task definitions
```

## Adding an Application

1. Create Helm chart in `k8s/<app>/`
2. Create Argo CD Application in `argocd/apps/<app>.yaml`
3. Reference in `argocd/apps/app-of-apps.yaml`

## Documentation

Full docs available at [http://localhost:8000](http://localhost:8000) via `task docs:serve`

## Core Principles

- **GitOps First** - All config in git, deployed via Argo CD
- **Values Overrides** - Never fork charts
- **Task-Based** - Use Taskfile for all operations
- **Minimal** - Simple scripts, clear YAML

## Resources

- [Argo CD Docs](https://argo-cd.readthedocs.io/)
- [Minikube Docs](https://minikube.sigs.k8s.io/)
- [Taskfile Docs](https://taskfile.dev/)
