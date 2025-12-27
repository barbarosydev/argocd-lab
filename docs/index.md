# Welcome

A local Kubernetes lab for learning GitOps with Argo CD on Minikube.

## What's Included

- **Minikube** - Local Kubernetes cluster (v1.35.0)
- **Argo CD** - GitOps continuous delivery tool

## Quick Links

- **[Setup](setup.md)** - Installation and configuration
- **[Tasks](tasks.md)** - Common commands
- **[Troubleshooting](troubleshooting.md)** - Common issues

## Getting Started

```bash
task install    # Install tools
task lab:start  # Start Minikube + Argo CD
```

Access Argo CD UI at <http://localhost:8081>

Get admin password:

```bash
task argocd:password
```

## Architecture

```text
Minikube → Argo CD → Ready to deploy applications
```

Argo CD is deployed and ready to manage applications using GitOps principles.

## Next Steps

- Access Argo CD UI
- Deploy your first application
- Learn GitOps workflows
- Use `task -l` to see all commands
