# Setup and Configuration

This guide provides instructions for setting up and configuring the ArgoCD Lab environment.

## Prerequisites

- **macOS**: With [Homebrew](https://brew.sh/) installed.
- **Docker**: Docker Desktop must be running.
- **Memory**: At least 4GB of RAM available for Minikube.

## Installation

The `install` task sets up all required tools and dependencies.

```bash
task install
```

This command installs:

- `kubectl`: Kubernetes command-line tool.
- `helm`: Kubernetes package manager.
- `minikube`: Local Kubernetes environment.
- `uv`: Python package manager.
- `jq`: Command-line JSON processor.
- `pre-commit`: Git hook manager.

## Private Repository Configuration

If you're working with a private GitHub repository, you need to configure a Personal Access Token (PAT) before starting
the lab.

```bash
export GITHUB_PAT=ghp_your_token_here
```

See the **[Private Repository Access](private-repository.md)** guide for detailed instructions.

## Lab Lifecycle

### Start the Lab

The `lab:start` task creates the Minikube cluster and deploys Argo CD.

```bash
task lab:start
```

### Stop the Lab

The `lab:stop` task deletes the Minikube cluster and cleans up resources.

```bash
task lab:stop
```

## Accessing Argo CD

- **URL**: `http://localhost:8081`
- **Username**: `admin`

To get the admin password, run:

```bash
task argocd:password
```

## Environment Configuration

Use a single `.env` file to configure all lab settings. Environment variables set in your shell take priority over
`.env`. Copy the template and adjust values as needed:

```bash
cp env.example .env
```

Key variables (defaults shown):

- `LAB_MINIKUBE_PROFILE=argocd-lab`
- `LAB_K8S_VERSION=v1.35.0`
- `LAB_ARGOCD_NAMESPACE=argocd`
- `LAB_ARGOCD_PORT=8081`
- `LAB_ARGO_VALUES=k8s/argocd/values.yaml`
- `LAB_ARGOCD_HELM_VERSION=9.3.4` (chart version used by default)
- `LAB_APP_NAMESPACE=default` (namespace used for direct Helm deploys)
- `LAB_DEPLOY_METHOD=gitops` (default deploy method for apps)
- `LAB_VERBOSE=0` (set to 1 for debug output)
- `GITHUB_PAT=` (optional; needed for private repos)

Tasks automatically load `.env` (via `dotenv` in `Taskfile.yml`), and scripts source it without overriding variables you
already exported. You can override any value per-invocation with standard environment overrides, for example:

```bash
LAB_ARGOCD_PORT=9090 task argocd:ui
```
