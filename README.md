# Argo CD Lab

[![CI](https://github.com/barbarosydev/argocd-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/barbarosydev/argocd-lab/actions)

Local Kubernetes lab for learning **GitOps** with **Argo CD** on **Minikube**.

## Quick Start

```bash
task utils:install     # Install tools (macOS)
task lab:up            # Start minikube + Argo CD
task argocd:password   # Get admin password
task argocd:ui         # Open UI (http://localhost:8081, user: admin)
```

> **Private repos?** Set `export GITHUB_PAT=ghp_...` before `task lab:up`

## Commands

| Command                  | Description               |
|--------------------------|---------------------------|
| `task lab:up`            | Start minikube + Argo CD  |
| `task lab:down`          | Stop lab (preserves data) |
| `task lab:nuke`          | Delete lab completely     |
| `task lab:status`        | Check lab status          |
| `task argocd:password`   | Get admin password        |
| `task argocd:deploy-app` | Deploy demo app           |

## Structure

```text
argocd/apps/     # Argo CD Application manifests
k8s/             # Helm charts (argocd, demo-api)
scripts/         # Automation scripts
docs/            # Documentation
```

## Docs

Run `task docs:serve` → [http://localhost:8000](http://localhost:8000)

## Resources

- [Argo CD](https://argo-cd.readthedocs.io/) · [Minikube](https://minikube.sigs.k8s.io/) · [Taskfile](https://taskfile.dev/)
