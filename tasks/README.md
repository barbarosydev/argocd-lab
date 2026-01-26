# Task Modules

This directory contains modular task definitions included in the main Taskfile.yml.

## Modules

- `lab.yml` - Lab lifecycle (up, down, nuke, status)
- `argocd.yml` - ArgoCD management (bootstrap, password, ui)
- `apps.yml` - Application management (list, sync, deploy, undeploy)
- `airflow.yml` - Airflow deployment (deploy, undeploy, ui, passwords, status)
- `docs.yml` - Documentation (serve, build, clean)
- `quality.yml` - Code quality (validate, hooks, run)
- `utils.yml` - Utilities (install, update, info, clean)

## Usage

```bash
# Lab tasks
task lab:up
task lab:down
task lab:status

# ArgoCD tasks
task argocd:ui
task argocd:password

# Apps tasks
task apps:list
task apps:deploy
task apps:undeploy

# Airflow tasks
task airflow:deploy
task airflow:ui

# Documentation tasks
task docs:serve
```

See `task --list` for all available tasks.
