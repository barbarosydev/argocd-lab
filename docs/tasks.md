# Task Reference

Quick reference for available tasks in the ArgoCD Lab.

## Quick Commands

```bash
task help      # Show all tasks
task start     # Start lab
task stop      # Stop lab
task status    # Check status
task ui        # Open ArgoCD UI
task deploy    # Deploy app
task undeploy  # Undeploy app
task validate  # Run validation
task info      # Show environment info
```

## Lab Commands

- `task lab:start` - Start Minikube cluster and deploy Argo CD (set LAB_VERBOSE=1 for verbose)
- `task lab:stop` - Stop and delete Minikube cluster
- `task lab:restart` - Restart the environment
- `task lab:status` - Check lab environment status

## ArgoCD Commands

- `task argocd:deploy` - Deploy/upgrade Argo CD
- `task argocd:password` - Get Argo CD admin password
- `task argocd:ui` - Open Argo CD UI in browser
- `task argocd:deploy-app` - Deploy application (default demo-api)
- `task argocd:undeploy-app` - Undeploy application

## Utils Commands

- `task utils:clean` - Clean artifacts

### Cleanup flags

`utils:clean` supports two opt-in flags:

- `FULL_CLEAN=1` stops and deletes the Minikube profile before cleaning local artifacts
- `DOCKER_CLEAN=1` removes `demo-api:*` images (it does not remove unrelated images)

You can set defaults in `.env` using:

- `LAB_FULL_CLEAN=0|1`
- `LAB_DOCKER_CLEAN=0|1`

Priority is:

1. Explicit env vars (`FULL_CLEAN`, `DOCKER_CLEAN`)
2. `.env` defaults (`LAB_FULL_CLEAN`, `LAB_DOCKER_CLEAN`)

Examples:

```bash
# one-off
FULL_CLEAN=1 DOCKER_CLEAN=1 task utils:clean

# set defaults once in .env
# LAB_FULL_CLEAN=1
# LAB_DOCKER_CLEAN=1

task utils:clean
```

## Quality Commands

- `task quality:validate` - Run pre-commit hooks and docs build
- `task quality:pre-commit:install|run|update` - Manage/run pre-commit hooks

Manual quality checks (run ad hoc as needed):

- Shell: `find scripts -name "*.sh" -exec shellcheck {} +`
- YAML: `yamllint .`
- Markdown: `markdownlint "**/*.md" --ignore node_modules --ignore site`
- Python format: `find . -name "*.py" -not -path "*/site/*" -not -path "*/.venv/*" -exec black {} +` and `isort`
- Tests: `task quality:test:demo-api` (removed from Taskfile; run directly via `uv run pytest -v` in `k8s/demo-api/app`)
