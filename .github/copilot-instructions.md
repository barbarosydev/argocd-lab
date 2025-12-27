# GitHub Copilot instructions

## Goals

- Maintain a Kind + Argo CD + Helm lab for Airflow, and other tools.
- Prefer values overrides over chart forks
- Keep the tools version management simple and provide latest stable version.

## Style

- Shell scripts must be minimal and readable.
- YAML must be minimal, with comments explaining local-only choices
- There should not be too much information in the docs.

## Tasks

- Add new Argo CD Applications under `argocd/apps/`
- Add charts/values for new tools under `k8s/<tool>/`
- Update docs under `docs/`
- This repo utilizes a Taskfile (<https://taskfile.dev/>).
  - Run `task install` (macOS only) to install Homebrew-managed dependencies.
  - Docs use uv as the package manager with a scoped `docs/pyproject.toml`.
  - Run `task docs:serve` to start a local docs server via `uv run --project docs mkdocs serve`.
  - Run `task docs:build` to build the documentation via `uv run --project docs mkdocs build`.
  - Run `task lab:start` to start the lab environment.
  - Run `task lab:stop` to stop the lab environment.
- Update .gitignore.
- Scripts should only be used for Taskfile tasks; there should not be any scripts for running solutions outside of
  Taskfile.
- Make sure versions in files are updated.
- One simple Python backend should be deployed to Argo CD as an app. This Python package should use uv as package
  manager.
  - The app only gives a ping response.
- Ensure <https://squidfunk.github.io/mkdocs-material/> is available for docs. Material for MkDocs is installed via uv
  using the `docs/pyproject.toml`, avoiding conflicts with externally managed Python environments.
