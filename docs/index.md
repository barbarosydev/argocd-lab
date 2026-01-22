# ArgoCD Lab

Local Kubernetes environment for learning GitOps with Argo CD.

## Quick Start

```bash
task utils:install    # Install tools (macOS)
task lab:up           # Start minikube + Argo CD
task argocd:password  # Get admin password
task argocd:ui        # Open UI (http://localhost:8081)
```

Login: `admin` / password from above.

## Next Steps

- [Setup](setup.md) – Installation & configuration
- [Deployment](deployment.md) – Deploy applications
- [Tasks](tasks.md) – Command reference
- [Troubleshooting](troubleshooting.md) – Common issues
