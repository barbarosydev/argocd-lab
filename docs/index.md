# Argo CD Lab

Welcome! This documentation guides you through setting up a local lab environment using Kind, Helm, Argo CD, and Airflow.

- Use the Setup page for dependency installation and running the environment.
- Explore Argo CD UI at https://localhost:8080 after setup.

## Prerequisites

- Docker Desktop installed and running
- Kind
- kubectl
- Helm
- uv (Python package manager)

> Note
> Tested only on macOS 26. This setup may not work on other platforms and is not guaranteed.

## Tool versions and official links

| Tool | Version | Official Link |
|------|---------|---------------|
| Python | 3.14.2 | [python.org](https://www.python.org/) |
| uv (Python pkg mgr) | Latest stable | [astral.sh/uv](https://astral.sh/uv/) |
| Kind | Latest stable | [kind.sigs.k8s.io](https://kind.sigs.k8s.io/) |
| Argo CD | Latest stable (Helm) | [Argo CD docs](https://argo-cd.readthedocs.io/) · [Artifact Hub chart](https://artifacthub.io/packages/helm/argo/argo-cd) |
| Helm | Latest stable | [helm.sh](https://helm.sh/) |
| MkDocs | 1.6.x | [mkdocs.org](https://www.mkdocs.org/) |
| Material for MkDocs | 9.5.x | [mkdocs-material](https://squidfunk.github.io/mkdocs-material/) |

Versions are pinned via `pyproject.toml` in docs and backend (Python 3.14.2). Other tools are kept at latest stable for local development. Use Taskfile commands to run docs via uv.
