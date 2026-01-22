# Tasks

Run `task --list` to see all available tasks.

## 🧪 Lab

| Task              | Description                      |
|-------------------|----------------------------------|
| `task lab:up`     | Start minikube and deploy ArgoCD |
| `task lab:down`   | Stop minikube (preserves data)   |
| `task lab:nuke`   | Delete minikube and all data     |
| `task lab:status` | Check lab status                 |

## 🔄 ArgoCD

| Task                       | Description            |
|----------------------------|------------------------|
| `task argocd:bootstrap`    | Deploy/upgrade Argo CD |
| `task argocd:password`     | Get admin password     |
| `task argocd:ui`           | Open UI in browser     |
| `task argocd:deploy-app`   | Deploy application     |
| `task argocd:undeploy-app` | Undeploy application   |

## 📦 Apps

| Task             | Description                |
|------------------|----------------------------|
| `task apps:sync` | Sync all ArgoCD apps       |
| `task apps:list` | List deployed applications |

## 📚 Docs

| Task               | Description              |
|--------------------|--------------------------|
| `task docs:serve`  | Serve docs (live reload) |
| `task docs:build`  | Build static site        |
| `task docs:deploy` | Deploy to GitHub Pages   |

## ✅ Quality

| Task                          | Description            |
|-------------------------------|------------------------|
| `task quality:validate`       | Run all checks         |
| `task quality:fix`            | Auto-fix lint errors   |
| `task quality:pre-commit:run` | Run pre-commit hooks   |

## 🔧 Utils

| Task                 | Description           |
|----------------------|-----------------------|
| `task utils:install` | Install dependencies  |
| `task utils:info`    | Show environment info |
| `task utils:clean`   | Clean local artifacts |
