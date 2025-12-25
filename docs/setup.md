# Setup

Minimal steps to use the lab with Taskfile and uv.

## Install dependencies (macOS only)

```bash
task install
```

## Docs

Serve locally (uv):
```bash
task docs:serve
```

Build site (uv):
```bash
task docs:build
```

## Start the lab

```bash
task lab:start
```

Argo CD UI:
```bash
task argocd:port-forward
# open https://localhost:8080
```

## Stop the lab

```bash
task lab:stop
```
