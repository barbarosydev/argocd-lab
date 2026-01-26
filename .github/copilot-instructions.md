# GitHub Copilot Instructions

## Project Overview

**Argo CD Lab** - Local Kubernetes environment for learning GitOps.

**Stack**: Minikube (v1.35.0), Argo CD, Helm, Taskfile, uv

## Core Principles

1. **GitOps** - All config in git, deployed via Argo CD
2. **Values Overrides** - Never fork charts
3. **Minimal** - Simple scripts, clear YAML
4. **Task-Based** - Use Taskfile for operations
5. **Silent Tasks** - All tasks use `silent: true` with human-readable output

## Repository Structure

```text
argocd-lab/
├── argocd/apps/       # Argo CD Application manifests
├── docs/              # MkDocs documentation
├── k8s/               # Helm charts and values
│   ├── argocd/
│   ├── airflow/
│   ├── postgres/
│   └── demo-api/
├── scripts/           # Shell scripts (used by Taskfile)
├── tasks/             # Task module files
│   ├── lab.yml
│   ├── argocd.yml
│   ├── postgres.yml
│   ├── airflow.yml
│   ├── apps.yml
│   ├── docs.yml
│   ├── quality.yml
│   └── utils.yml
└── Taskfile.yml       # Task definitions
```

## Key Commands

```bash
# Setup
task utils:install              # Install tools (macOS)
task quality:hooks              # Install git hooks

# Lab lifecycle
task lab:up                     # Start lab (minikube + ArgoCD)
task lab:down                   # Stop lab (preserves data)
task lab:nuke                   # Delete lab completely
task lab:status                 # Check status

# ArgoCD
task argocd:password            # Get admin password
task argocd:ui                  # Open browser

# Apps
task apps:list                  # List deployed apps
task apps:deploy                # Deploy app (GitOps)
task apps:undeploy              # Undeploy app

# PostgreSQL
task postgres:deploy            # Deploy PostgreSQL (Helm)
task postgres:deploy-gitops     # Deploy PostgreSQL (GitOps)
task postgres:status            # Check status
task postgres:password          # Show credentials
task postgres:undeploy          # Remove PostgreSQL

# Airflow (requires PostgreSQL first)
task airflow:deploy             # Deploy Airflow
task airflow:ui                 # Open Airflow UI
task airflow:passwords          # Show credentials
task airflow:status             # Check status

# Development
task docs:serve                 # Serve documentation
task quality:validate           # Run all checks
task utils:info                 # Show environment info
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
- No colons in quoted strings (use plain text)

### Python

- Follow PEP 8, line length 120
- Use black, isort, flake8
- Type hints encouraged

### Taskfile

- Short descriptions (one line)
- All tasks must have `silent: true`
- Use `echo` for human-readable output
- Use `deps:` for task dependencies
- No colons in commit messages or quoted strings

## Deployment Methods

Applications support two deployment methods:

1. **GitOps** (default) - Deploy via ArgoCD using `--method gitops`
2. **Helm** - Direct Helm deployment using `--method helm`

Scripts auto-detect deployment method and suggest corrections.

## Adding Applications

1. Create Helm chart in `k8s/<app>/`
2. Create Argo CD Application in `argocd/apps/<app>.yaml`
3. Document in `docs/deployment.md`

## File Naming

- Scripts: `kebab-case.sh`
- YAML: `kebab-case.yaml`
- Docs: `kebab-case.md`
- Python: `snake_case.py`

## Documentation

- All documentation in `/docs` directory
- Only `README.md` allowed in root
- Update `docs/` when adding features
- Keep documentation minimal and focused

## Pre-commit Hooks

Run before committing:

```bash
task quality:run
```

Checks: markdown, shell, YAML, Python, Dockerfile

## Resources

- [Argo CD Docs](https://argo-cd.readthedocs.io/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Taskfile Docs](https://taskfile.dev/)
