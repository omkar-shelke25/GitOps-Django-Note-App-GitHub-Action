
# 🗒️ Django Note App Deployment with GitOps (ArgoCD + EKS)

This project demonstrates a complete **GitOps-based** deployment workflow for a Django Notes application. We use **GitHub Actions** for automation and **ArgoCD** for continuous deployment into an **Amazon EKS** cluster. Infrastructure is managed using **Kustomize** for environment-specific manifests.

---

## 🚀 Tech Stack

| Tool | Purpose |
|------|---------|
| **Django** | Backend framework |
| **MySQL** | Database |
| **Nginx** | Reverse proxy |
| **Docker** | Containerization |
| **GitHub Actions** | Workflow automation |
| **Kustomize** | Kubernetes overlay management |
| **ArgoCD** | GitOps-based deployment |
| **Amazon EKS** | Kubernetes cluster |

---

## 📁 Project Structure

```
.
├── Dockerfile                   # Django backend
├── nginx/Dockerfile            # Nginx reverse proxy
├── docker-compose.yml          # Local dev stack
├── requirements.txt            # Python deps
├── noteapp-kustomize/          # Kustomize base and overlays
│   ├── base/
│   └── overlays/{staging,production}/
├── argocd/
│   ├── app-staging.yaml
│   └── app-production.yaml
└── .github/workflows/
    └── noteapp-gitops-pipelines.yml
```

---

## 🔁 Workflow Automation (via GitHub Actions)

### 🔄 Triggered On:
- Push to `main` (deploys to **staging** environment)
- Manual `workflow_dispatch` (triggers **production** deployment)

---

### 🧱 Workflow Job Summary

![image](https://github.com/user-attachments/assets/67c47143-1639-4551-8325-9bd03afbff3c)

#### 1️⃣ `docker-build`
- Builds `noteapp-backend` and `noteapp-nginx` Docker images
- Saves them as artifacts

#### 2️⃣ `smoke-test`
- Loads Docker images
- Spins up app using `docker-compose` (MySQL + Django + Nginx)
- Verifies availability using `curl`

📦 **Output**:
```
MySQL is healthy!
Django is healthy!
Running smoke test...
Smoke test passed!
```

#### 3️⃣ `docker-push`
- Tags images using Git SHA
- Pushes them to DockerHub using secrets

#### 4️⃣ `update-kustomization`
- Updates image tags in `kustomization.yaml` using `yq`
- Commits changes back to repo

```bash
Updated image tags to abc1234 in kustomization.yaml
```

#### 5️⃣ `django-note-app-staging-deploy`
- Applies ArgoCD `app-staging.yaml` using `kubectl`
- ArgoCD auto-syncs changes in staging

📸 **Staging CLI Output**:  
![Staging CLI](https://github.com/user-attachments/assets/81b02c05-0316-49c4-aa42-26c0315f092c)

#### 6️⃣ `django-note-app-production-deploy`
- Manual trigger deploys production ArgoCD manifest

📸 **Production CLI Output**:  
![Production CLI](https://github.com/user-attachments/assets/8b1ca8fd-0dce-42ff-9ce1-f45ba89f451d)

---

## 🌐 ArgoCD Dashboards
![ArgoCD Production](https://github.com/user-attachments/assets/383e09ea-0830-4364-a9bb-5e20fc0a352a)

### 🔄 Staging App  
![ArgoCD Staging](https://github.com/user-attachments/assets/b8cdd90e-619b-46fa-9881-1b83b689c6c9)

### 🔄 Production App  
![image](https://github.com/user-attachments/assets/1aa3a0e7-1085-4ebe-9836-fe90e0e09298)

---

## ✅ Final Application Output

![Final Output](https://github.com/user-attachments/assets/d5b40640-e427-4e38-b26e-dcf231b05590)

---

## 🧪 Run Locally

```bash
git clone <repo-url>
cd <repo>
```

### 🔐 `.env` setup:
```bash
cat <<EOF > .env
DATABASE_HOST=db
DATABASE_NAME=test_db
DATABASE_USER=root
DATABASE_PASSWORD=root
DATABASE_PORT=3306
EOF
```

### 🐳 Start services:
```bash
docker-compose up -d
```

### 🌐 Access:
`http://localhost:80`

### 🧹 Stop services:
```bash
docker-compose down --volumes
```

---

## 🔐 GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `DOCKER_USERNAME` | DockerHub login |
| `DOCKER_PASS` | DockerHub password |
| `GIT_TOKEN` | Git commit access |
| `KUBECONFIG` | EKS cluster kubeconfig |

---

## 🔁 GitOps Workflow

```mermaid
graph TD;
  Push[Push to main] --> Build[Docker Build]
  Build --> Test[Smoke Test]
  Test --> PushRegistry[Push Docker Images]
  PushRegistry --> UpdateKustomize[Update kustomization.yaml]
  UpdateKustomize --> ArgoCD[ArgoCD Auto Sync]
  ArgoCD --> Staging[Staging Deployment]
  Staging --> ManualTrigger[Manual Dispatch]
  ManualTrigger --> Production[Production Deployment]
```

---


