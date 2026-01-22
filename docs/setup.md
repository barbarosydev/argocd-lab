# Setup

## Prerequisites

- **macOS** with [Homebrew](https://brew.sh/)
- **Docker Desktop** running
- **4GB RAM** available for Minikube

## Installation

```bash
task utils:install
```

Installs: `kubectl`, `helm`, `minikube`, `uv`, `jq`, `pre-commit`

## Private Repositories

For private GitHub repos, set your PAT before starting:

```bash
export GITHUB_PAT=ghp_your_token_here
```

See [Private Repository Access](private-repository.md) for details.

## Lab Lifecycle

```bash
task lab:up      # Start minikube + Argo CD
task lab:down    # Stop (preserves data)
task lab:nuke    # Delete completely
task lab:status  # Check status
```

## Argo CD Access

- **URL**: <http://localhost:8081>
- **User**: `admin`
- **Password**: `task argocd:password`

## Configuration

Copy and edit `.env`:

```bash
cp env.example .env
```

Key settings:

| Variable               | Default      | Description                    |
|------------------------|--------------|--------------------------------|
| `LAB_MINIKUBE_PROFILE` | `argocd-lab` | Minikube profile name          |
| `LAB_K8S_VERSION`      | `v1.35.0`    | Kubernetes version             |
| `LAB_MINIKUBE_DRIVER`  | `docker`     | Minikube driver                |
| `LAB_ARGOCD_PORT`      | `8081`       | Argo CD UI port                |
| `GITHUB_PAT`           | _(empty)_    | GitHub token for private repos |

Override per-command: `LAB_ARGOCD_PORT=9090 task argocd:ui`
