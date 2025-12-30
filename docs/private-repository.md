# Private Repository Access

Configure ArgoCD to access your private GitHub repository using a Personal Access Token.

## Creating a GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → **Fine-grained tokens**
2. Click "Generate new token"
3. Configure the token:
    - **Token name**: `ArgoCD Lab Access`
    - **Expiration**: 90 days (recommended)
    - **Repository access**: Select "Only select repositories"
    - Choose your repository: `barbarosydev/argocd-lab`
4. Under "Repository permissions":
    - **Contents**: Read-only
    - **Metadata**: Read-only (auto-selected)
5. Click "Generate token"
6. **Copy the token immediately**

## Configuration

### Set Environment Variable

Export your GitHub PAT:

```bash
export GITHUB_PAT=ghp_your_token_here
```

For persistence, add to your shell profile:

```bash
echo 'export GITHUB_PAT=ghp_your_token_here' >> ~/.zshrc
source ~/.zshrc
```

### Deploy ArgoCD

```bash
task lab:start
```

Or redeploy if already running:

```bash
task argocd:deploy
```

The script automatically detects and configures the credentials.

## Verification

Check that credentials are configured:

```bash
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=repository
```

## Troubleshooting

### Authentication Required Error

Failed to load the target state: authentication required

Set the `GITHUB_PAT` variable and redeploy:

```bash
export GITHUB_PAT=ghp_your_token_here
task argocd:deploy
```

### Invalid or Expired Token

Generate a new PAT, update the variable, and redeploy:

```bash
export GITHUB_PAT=ghp_your_new_token
task argocd:deploy
```

## Security Best Practices

- **Never commit PAT to Git** - Always use environment variables
- **Use minimal permissions** - Grant only `Contents: Read-only`
- **Set expiration dates** - Rotate tokens every 90 days
- **Store securely** - Use a password manager or vault
- **Revoke unused tokens** - Regularly audit and clean up
