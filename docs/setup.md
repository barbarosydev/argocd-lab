# Setup

Minimal steps to use the lab with Taskfile.

## Install dependencies

```bash
task install
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

## Docs

```bash
task docs:serve
# or
task docs:build
```
