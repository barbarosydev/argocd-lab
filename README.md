# ArgoCD Lab

A local lab using Kind, Helm, Argo CD, and Airflow.

- Install deps: use Taskfile
- Start/stop lab: use Taskfile
- Docs: MkDocs Material under `docs/`

Usage:

- Install dependencies:
  - task install
- Start lab:
  - task lab:start
- Stop lab:
  - task lab:stop
- Serve docs:
  - task docs:serve
- Build docs:
  - task docs:build

Argo CD UI will be available via port-forward task or at https://localhost:8080 if already forwarded.
