# Task Reference

Quick reference for all available tasks. Run `task -l` to see the full list.

## Lab Management

```bash
task lab:start          # Start complete lab (Minikube + Argo CD)
task lab:stop           # Stop lab and cleanup
task lab:restart        # Restart the lab
task lab:status         # Check environment status
```

## Environment

```bash
task env:start          # Start Minikube and deploy Argo CD
task env:start:verbose  # Start with debug output
task env:stop           # Stop and delete cluster
task env:restart        # Restart environment
```

## Argo CD

```bash
task argocd:deploy      # Deploy/upgrade Argo CD
task argocd:password    # Get admin password
task argocd:ui          # Open UI in browser
```

## Documentation

```bash
task docs:serve         # Serve with live reload
task docs:build         # Build static site
task docs:clean         # Clean build artifacts
```

## Development & Quality

```bash
task install            # Install dependencies (first time)
task pre-commit:install # Install git hooks
task pre-commit:run     # Run all checks
task pre-commit:update  # Update hook versions
task validate           # Run all validation
```

## Cleanup

```bash
task clean              # Clean build artifacts
task clean:all          # Deep clean (stop lab + cleanup)
```

## Quick Start

```bash
# First time setup
task install
task pre-commit:install

# Start working
task lab:start
task argocd:password
task argocd:ui

# When done
task lab:stop
```

## Accessing Argo CD

After running `task lab:start`:

**URL**: <http://localhost:8081>

**Get Password**:

```bash
task argocd:password
```

**Open UI**:

```bash
task argocd:ui
```

**Login**:

- Username: admin
- Password: (from command above)

## Tips

- Use `task -l` to see all available tasks
- Use `task <task-name> --summary` to see task details
- Tasks have dependency checks (will warn if prerequisites missing)
- Verbose mode available for debugging: `task env:start:verbose`
