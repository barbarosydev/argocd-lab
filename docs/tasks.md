# Tasks

Run `task --list` to see all available tasks.

## 🌱 Top-level

| Task          | Description                |
|---------------|----------------------------|
| `task init`   | Create .env from template  |

## 🔬 Lab

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

## ✈️ Airflow

| Task                    | Description                        |
|-------------------------|------------------------------------|
| `task airflow:deploy`   | Deploy Airflow via ArgoCD          |
| `task airflow:undeploy` | Undeploy Airflow                   |
| `task airflow:status`   | Check Airflow deployment status    |
| `task airflow:ui`       | Port-forward and access Airflow UI |
| `task airflow:logs`     | View scheduler logs                |
| `task airflow:shell`    | Open shell in scheduler pod        |
| `task airflow:sync`     | Force sync Airflow in ArgoCD       |

## 📚 Docs

| Task              | Description                   |
|-------------------|-------------------------------|
| `task docs:serve` | Serve docs (live reload)      |
| `task docs:build` | Build static site             |
| `task docs:clean` | Clean documentation artifacts |

## ✅ Quality

| Task                          | Descr«iption         |
|-------------------------------|----------------------|
| `task quality:validate`       | Run all checks       |
| `task quality:fix`            | Auto-fix lint errors |
| `task quality:pre-commit:run` | Run pre-commit hooks |

## ⚙️ Utils

| Task                 | Description           |
|----------------------|-----------------------|
| `task utils:install` | Install dependencies  |
| `task utils:info`    | Show environment info |
| `task utils:clean`   | Clean local artifacts |
