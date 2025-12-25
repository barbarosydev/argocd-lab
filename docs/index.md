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

> ℹ️ Note
> This setup has been tested only on macOS 26. It may not work on other platforms and is not guaranteed.

## Tool versions and links

- Python: 3.14.2 (required globally) — [python.org](https://www.python.org/)
- uv (Python package manager): latest stable — [astral.sh/uv](https://astral.sh/uv/)
- Kind: latest stable — [kind.sigs.k8s.io](https://kind.sigs.k8s.io/)
- Argo CD: latest stable via Helm chart — [Argo CD docs](https://argo-cd.readthedocs.io/) • [Helm chart on Artifact Hub](https://artifacthub.io/packages/helm/argo/argo-cd)
- Helm: latest stable — [helm.sh](https://helm.sh/)
- MkDocs: 1.6.x — [mkdocs.org](https://www.mkdocs.org/)
- Material for MkDocs: 9.5.x — [squidfunk.github.io/mkdocs-material](https://squidfunk.github.io/mkdocs-material/)

Versions are pinned where necessary via `pyproject.toml` (docs and backend) and otherwise kept at latest stable for local development. Use Taskfile commands to run docs via uv.
