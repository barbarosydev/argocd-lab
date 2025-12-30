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

- `task lab:start` - Start Minikube cluster and deploy Argo CD
- `task lab:start:verbose` - Start with verbose logging
- `task lab:stop` - Stop and delete Minikube cluster
- `task lab:restart` - Restart the environment
- `task lab:status` - Check lab environment status

## ArgoCD Commands

- `task argocd:deploy` - Deploy/upgrade Argo CD
- `task argocd:password` - Get Argo CD admin password
- `task argocd:ui` - Open Argo CD UI in browser
- `task argocd:deploy-app` - Deploy application (default demo-api)
- `task argocd:undeploy-app` - Undeploy application
- `task argocd:list-apps` - List all ArgoCD applications
- `task argocd:sync-app` - Sync an ArgoCD application

## Documentation Commands

- `task docs:serve` - Serve documentation with live reload
- `task docs:build` - Build static documentation
- `task docs:clean` - Clean documentation artifacts
- `task docs:deploy` - Deploy documentation to GitHub Pages

## Quality Commands

- `task quality:pre-commit:install` - Install pre-commit git hooks
- `task quality:pre-commit:run` - Run all pre-commit hooks
- `task quality:pre-commit:update` - Update pre-commit hook versions
- `task quality:validate` - Run all validation checks
- `task quality:lint:shell` - Lint shell scripts
- `task quality:lint:yaml` - Lint YAML files
- `task quality:lint:markdown` - Lint Markdown files
- `task quality:format:python` - Format Python code
- `task quality:test:demo-api` - Run demo-api tests

## Utility Commands

- `task utils:clean` - Clean build artifacts
- `task utils:clean:all` - Deep clean (stop lab + clean artifacts)
- `task utils:clean:docker` - Clean Docker resources
- `task utils:install` - Install required dependencies
- `task utils:update` - Update all dependencies
- `task utils:info` - Show lab environment information
