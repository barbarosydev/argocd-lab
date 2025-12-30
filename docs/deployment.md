# Application Deployment

This guide covers how to deploy and manage applications in the ArgoCD Lab.

## Deployment Methods

The lab supports two primary deployment methods. The scripts include auto-detection to guide you if you use the wrong
method for a given state.

### 1. GitOps Method (Default)

This is the recommended method for managing applications. It uses Argo CD to maintain the desired state from Git.

- **Continuous Sync**: Automatically syncs with the Git repository.
- **Self-Healing**: Reverts any manual changes to maintain the desired state.
- **Rollback**: Supports automated rollbacks to previous versions.

### 2. Helm Method

This method allows for direct deployment using Helm, bypassing Argo CD. It is useful for quick testing and local
development.

- **Quick Iteration**: Test chart changes without committing to Git.
- **No Overhead**: Avoids the Argo CD sync loop during development.

## Deploying the `demo-api`

The `demo-api` is a sample FastAPI application included in this repository.

### Deploy

- **GitOps**:

  ```bash
  task deploy
  ```

- **Helm**:

  ```bash
  task deploy -- --method helm
  ```

### Undeploy

- **GitOps**:

  ```bash
  task undeploy
  ```

- **Helm**:

  ```bash
  task undeploy -- --method helm
  ```

### Accessing the Application

1. **Port-forward to the service**:

    ```bash
    kubectl port-forward svc/demo-api 8080:80
    ```

2. **Test the endpoints** in another terminal:

    ```bash
    # Health check
    curl http://localhost:8080/health

    # Ping
    curl http://localhost:8080/ping
    ```

### Running Tests

To run the application's test suite, use the following command:

```bash
task quality:test:demo-api
```
