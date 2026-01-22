# Private Repository Access

Configure ArgoCD to access private GitHub repositories.

## Create GitHub Token

1. GitHub → Settings → Developer settings → Personal access tokens → **Fine-grained tokens**
2. Generate new token:
    - **Name**: `ArgoCD Lab`
    - **Expiration**: 90 days
    - **Repository access**: Select your repo
    - **Permissions**: Contents (Read-only)
3. Copy the token

## Configure

```bash
export GITHUB_PAT=ghp_your_token_here
task up    # Or: task argocd:bootstrap (if already running)
```

For persistence:

```bash
echo 'export GITHUB_PAT=ghp_your_token_here' >> ~/.zshrc
```

## Verify

```bash
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=repository
```

## Troubleshooting

**Authentication errors?** Set token and redeploy:

```bash
export GITHUB_PAT=ghp_your_token_here
task argocd:bootstrap
```

## Security Best Practices

- **Never commit PAT to Git** - Always use environment variables
- **Use minimal permissions** - Grant only `Contents: Read-only`
- **Set expiration dates** - Rotate tokens every 90 days
- **Store securely** - Use a password manager or vault
- **Revoke unused tokens** - Regularly audit and clean up
