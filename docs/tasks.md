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

## 📦 Apps

| Task                 | Description                |
|----------------------|----------------------------|
| `task apps:list`     | List deployed applications |
| `task apps:sync`     | Sync all ArgoCD apps       |
| `task apps:deploy`   | Deploy an application      |
| `task apps:undeploy` | Undeploy an application    |

## ✈️ Airflow

| Task                     | Description                           |
|--------------------------|---------------------------------------|
| `task airflow:deploy`    | Deploy Airflow with PostgreSQL        |
| `task airflow:undeploy`  | Undeploy Airflow and PostgreSQL       |
| `task airflow:ui`        | Open Airflow web UI (port-forward)    |
| `task airflow:passwords` | Show Airflow and PostgreSQL passwords |
| `task airflow:status`    | Check Airflow deployment status       |

## 📚 Docs

| Task              | Description                   |
|-------------------|-------------------------------|
| `task docs:serve` | Serve docs (live reload)      |
| `task docs:build` | Build static site             |
| `task docs:clean` | Clean documentation artifacts |

## ✅ Quality

| Task                    | Description               |
|-------------------------|---------------------------|
| `task quality:validate` | Run all validation checks |
| `task quality:hooks`    | Install pre-commit hooks  |
| `task quality:run`      | Run pre-commit hooks      |

## ⚙️ Utils

| Task                 | Description             |
|----------------------|-------------------------|
| `task utils:install` | Install dependencies    |
| `task utils:update`  | Update dependencies     |
| `task utils:info`    | Show environment info   |
| `task utils:clean`   | Clean local artifacts   |
