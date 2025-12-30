# Welcome to the ArgoCD Lab

This project provides a local Kubernetes environment for learning GitOps with Argo CD and Minikube.

## Core Components

- **Minikube**: A local Kubernetes cluster.
- **Argo CD**: A declarative, GitOps continuous delivery tool.
- **Helm**: The package manager for Kubernetes.
- **Taskfile**: A task runner for automating development and operational tasks.

## Getting Started

To get started with the lab, follow these steps:

1. **Installation**: Run the following command to install the necessary tools and dependencies:

    ```bash
    task install
    ```

2. **Start the Lab**: Start the Minikube cluster and deploy Argo CD:

    ```bash
    task lab:start
    ```

3. **Access Argo CD UI**: Open the Argo CD web interface in your browser:

    ```bash
    task argocd:ui
    ```

    The UI is available at `http://localhost:8081`.

4. **Login**: Use the username `admin` and get the password by running:

    ```bash
    task argocd:password
    ```

## Next Steps

- **[Setup](setup.md)**: Detailed installation and configuration instructions.
- **[Private Repository Access](private-repository.md)**: Configure access to private GitHub repositories.
- **[Deploying Applications](deployment.md)**: Learn how to deploy applications in the lab.
- **[Task Reference](tasks.md)**: A complete list of available tasks.
- **[Troubleshooting](troubleshooting.md)**: Solutions to common problems.
