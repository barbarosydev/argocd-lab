# Getting Started

This guide helps you install tools and start the local lab quickly, using Taskfile and uv.

## Overview

- Taskfile provides simple, repeatable commands (<https://taskfile.dev/>)
- Docs are served with uv using `docs/pyproject.toml`
- The lab uses Minikube + Helm + Argo CD, with apps managed by Argo CD

## Prerequisites

- macOS with Homebrew (this setup is tested only on macOS 26; other platforms are not guaranteed)
- Docker Desktop installed and running (or a supported VM driver for Minikube)
- Internet access to pull images and Python packages

## Install tooling (macOS only)

```bash
# Installs minikube, kubectl, helm, uv, mkdocs, mkdocs-material via Homebrew
task install
```

## Using Taskfile

Common commands:

- Serve docs (auto-reload):

  ```bash
  task docs:serve
  ```

- Build docs:

  ```bash
  task docs:build
  ```

- Clean docs outputs and local venvs:

  ```bash
  task docs:clean
  ```

- Start the lab:

  ```bash
  task lab:start
  ```

- Stop the lab:

  ```bash
  task lab:stop
  ```

- Port-forward Argo CD UI:

  ```bash
  task argocd:port-forward
  # open https://localhost:8080
  ```

## Advanced: lab-start flags

The lab start script `scripts/lab-start.sh` accepts flags and environment overrides:

- Flags (override environment defaults):
  - `--profile <name>` (alias: `--cluster-name`) (default: argocd-lab)
  - `--k8s-version <k8s version>` (default: v1.35.0)
  - `--argocd-namespace <name>` (default: argocd)
  - `--airflow-namespace <name>` (default: airflow)
  - `--argo-values <path>` (default: k8s/argocd/values.yaml)
  - `--apps-path <path>` (default: argocd/apps)

Examples:

```bash
# Use a custom profile
./scripts/lab-start.sh --profile mylab

# Pin a specific Kubernetes version for Minikube
./scripts/lab-start.sh --k8s-version v1.35.0
```

## Notes

- MkDocs serves with live reload and watches `docs/`. If pages don’t auto-refresh:
  - Disable “safe write” in your editor (atomic saves can break file watch)
  - Ensure you’re editing files under `docs/`
  - Check the server output for errors
- Argo CD initial admin password (if needed):

  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode
  ```
