# GitHub Copilot Instructions

## Project Overview

**Argo CD Lab** - Local Kubernetes environment for learning GitOps.

**Stack**: Minikube (v1.35.0), Argo CD, Helm, Taskfile, uv

## Core Principles

1. **GitOps** - All config in git, deployed via Argo CD
2. **Values Overrides** - Never fork charts
3. **Minimal** - Simple scripts, clear YAML
4. **Task-Based** - Use Taskfile for operations

## Repository Structure

```text
argocd-lab/
├── argocd/apps/       # Argo CD Application manifests
├── docs/              # MkDocs documentation
├── k8s/               # Helm charts and values
│   ├── airflow/
│   ├── argocd/
│   └── backend/
├── scripts/           # Shell scripts (used by Taskfile)
│   ├── minikube-start.sh
│   ├── minikube-stop.sh
│   ├── argocd-deploy.sh
│   └── setup-dependencies.sh
└── Taskfile.yml       # Task definitions
```

## Key Commands

```bash
task install      # Install tools (macOS)
task lab:start    # Start env + deploy apps
task lab:stop     # Stop and cleanup
task docs:serve   # Serve documentation
```

## Coding Standards

### Shell Scripts

- Use `#!/usr/bin/env bash` and `set -euo pipefail`
- Quote all variables: `"${VAR}"`
- Support `--help` and `--verbose` flags
- Must pass `shellcheck`

### YAML

- 2-space indentation
- Comments for non-obvious config
- Group related settings

### Python

- Follow PEP 8, line length 120
- Use black, isort, flake8
- Type hints encouraged

### Taskfile

- Short descriptions (one line)
- Quote commands with colons

## Adding Applications

1. Create Helm chart in `k8s/<app>/`
2. Create Argo CD Application in `argocd/apps/<app>.yaml`
3. Reference in `argocd/apps/app-of-apps.yaml`

## File Naming

- Scripts: `kebab-case.sh`
- YAML: `kebab-case.yaml`
- Docs: `kebab-case.md`
- Python: `snake_case.py`

## Pre-commit Hooks

Run before committing:

```bash
task pre-commit:run
```

Checks: markdown, shell, YAML, Python, Dockerfile, Helm

## Common Tasks

- Add new apps to `k8s/` and `argocd/apps/`
- Update Helm values in `k8s/*/values.yaml`
- Improve docs in `docs/`
- Fix scripts in `scripts/`
- Add Taskfile tasks

## Resources

- [Argo CD Docs](https://argo-cd.readthedocs.io/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Taskfile Docs](https://taskfile.dev/)
