# Task Modules

This directory contains modular task definitions included in the main Taskfile.yml.

## Modules

- `lab.yml` - Lab lifecycle (start, stop, restart, status)
- `argocd.yml` - ArgoCD management (deploy, ui, apps)
- `airflow.yml` - Apache Airflow 3 deployment and management
- `apps.yml` - Application sync and listing
- `docs.yml` - Documentation (serve, build, clean)
- `quality.yml` - Code quality (pre-commit, lint, test)
- `utils.yml` - Utilities (clean, install, info)

## Usage

```bash
# Lab tasks
task lab:start
task lab:stop

# ArgoCD tasks
task argocd:ui
task argocd:deploy-app

# Airflow tasks
task airflow:deploy
task airflow:status
task airflow:ui

# Documentation tasks
task docs:serve

# Or use shortcuts
task start      # → task lab:start
task deploy     # → task argocd:deploy-app
```

See `task --list` for all available tasks.
