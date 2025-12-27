# Setup

## Prerequisites

- macOS with Homebrew
- Docker Desktop running
- 4GB+ RAM available

## Install

```bash
task install
```

Installs: kubectl, helm, minikube, uv, jq, pre-commit

## Start the Lab

```bash
task lab:start
```

This will:

1. Create Minikube cluster
2. Install Argo CD
3. Deploy applications

## Access Argo CD

**URL**: <http://localhost:8081>

**Username**: `admin`

**Get Password**:

```bash
task argocd:password
```

## Configuration

Edit `Taskfile.yml` to change defaults:

```yaml
vars:
  PROFILE: argocd-lab
  K8S_VERSION: v1.35.0
  ARGOCD_NAMESPACE: argocd
  AIRFLOW_NAMESPACE: airflow
```

## Stop the Lab

```bash
task lab:stop
```

Deletes the Minikube cluster and stops port-forwards.
