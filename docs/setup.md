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

You can customize the lab environment by editing the `vars` section in `Taskfile.yml`.

```yaml
vars:
  PROFILE: argocd-lab
  K8S_VERSION: "v1.35.0"
  ARGOCD_NAMESPACE: argocd
  ARGOCD_PORT: 8081
```

Key variables include:

- `PROFILE`: The Minikube profile name.
- `K8S_VERSION`: The Kubernetes version to use.
- `ARGOCD_NAMESPACE`: The namespace for Argo CD.
- `ARGOCD_PORT`: The port for the Argo CD UI.
