# Argo CD Lab

[![CI](https://github.com/barbarosydev/argocd-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/barbarosydev/argocd-lab/actions)

A local Kubernetes lab for learning GitOps with **Argo CD** on **Minikube**.

## Quick Start

```bash
# Install dependencies (macOS)
task install

# Start Minikube and deploy Argo CD
task lab:start

# Get Argo CD admin password
task argocd:password

# Access Argo CD UI at http://localhost:8081
# Username: admin
# Password: (from command above)
```

## Architecture

```text
Minikube Cluster
└── Argo CD (argocd namespace)
    └── Ready to deploy applications
```

## Key Commands

| Command                | Description                |
|------------------------|----------------------------|
| `task install`         | Install tools (macOS)      |
| `task lab:start`       | Start Minikube + Argo CD   |
| `task lab:stop`        | Stop and cleanup           |
| `task argocd:password` | Get Argo CD admin password |
| `task docs:serve`      | Serve documentation        |

## Repository Structure

```text
.
├── docs/                 # Documentation
├── k8s/                  # Helm charts and values
│   └── argocd/          # Argo CD values
├── scripts/              # Automation scripts
│   ├── minikube-start.sh
│   ├── minikube-stop.sh
│   ├── argocd-deploy.sh
│   └── setup-dependencies.sh
└── Taskfile.yml          # Task definitions
```

## What Gets Deployed

1. **Minikube** - Local Kubernetes cluster (v1.35.0)
2. **Argo CD** - Installed via Helm with custom values
3. **Port-forward** - Argo CD UI accessible at <http://localhost:8081>

## Documentation

Full documentation at [http://localhost:8000](http://localhost:8000) via `task docs:serve`

- **[Setup](docs/setup.md)** - Installation and configuration
- **[Tasks](docs/tasks.md)** - Command reference
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues

## Core Principles

- **GitOps First** - All config in git, deployed via Argo CD
- **Values Overrides** - Never fork charts
- **Task-Based** - Use Taskfile for all operations
- **Minimal** - Simple scripts, clear YAML

## Resources

- [Argo CD Docs](https://argo-cd.readthedocs.io/)
- [Minikube Docs](https://minikube.sigs.k8s.io/)
- [Taskfile Docs](https://taskfile.dev/)
