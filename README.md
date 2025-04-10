# 🚀 Django Note App Deploy Using GitOps

This project demonstrates how to deploy a Django-based Notes application using **GitOps principles**. It leverages **ArgoCD** for continuous deployment, **Kustomize** for Kubernetes manifest management, and **Amazon EKS** as the deployment environment. The entire CI/CD process is automated using **GitHub Actions**.

---

## ✅ Prerequisites

Ensure the following tools are installed before running the project locally or deploying to the cloud:

- **Python** & **Django**
- **Nginx** (reverse proxy)
- **MySQL** (database)
- **Docker** & **Docker Compose**
- **kubectl**
- **Amazon EKS**
- **ArgoCD**
- **GitHub Actions**

---

## 📁 Project Structure

```
├── Dockerfile
├── docker-compose.yml
├── nginx/
├── noteapp-kustomize/
├── argocd/
├── requirements.txt
└── .github/workflows/noteapp-gitops-pipelines.yml
```

- `Dockerfile`: Django backend image
- `nginx/`: Nginx configuration and Dockerfile
- `noteapp-kustomize/`: Kustomize base and overlays for staging/production
- `argocd/`: ArgoCD application manifests
- `.github/workflows/`: GitHub Actions CI/CD definitions

---

## ⚙️ CI/CD Pipeline Overview

### 1. **Docker Build**
- **Triggers**: Push to `main`, `feature/**`, PR merges
- **Artifacts**: `noteapp-backend.tar`, `noteapp-nginx.tar`

---

### 2. **Smoke Test**

Runs local test environment using Docker Compose.

```
MySQL is healthy!
Django is healthy!
Smoke test passed!
```

---

### 3. **Docker Push**

Pushes Docker images to DockerHub with tags like:  
`username/noteapp-backend:<short_sha>`

---

### 4. **Update Kustomization**

Updates image tags in `noteapp-kustomize/base/kustomization.yaml` and commits the changes.

```bash
Updated image tags to abc1234 in kustomization.yaml
```

---

### 5. **Staging Deployment** (Auto)

Applies `app-staging.yaml` to ArgoCD.  
⬇️ *Staging Deployment CLI Output*  
![Staging CLI Output](https://github.com/user-attachments/assets/81b02c05-0316-49c4-aa42-26c0315f092c)

---

### 6. **Production Deployment** (Manual via `workflow_dispatch`)

Applies `app-production.yaml` to ArgoCD.

⬇️ *ArgoCD Production View*  
![ArgoCD Production](https://github.com/user-attachments/assets/383e09ea-0830-4364-a9bb-5e20fc0a352a)

⬇️ *ArgoCD Staging View*  
![ArgoCD Staging](https://github.com/user-attachments/assets/b8cdd90e-619b-46fa-9881-1b83b689c6c9)

---

## 🎯 Final Output

The application is successfully deployed and accessible.

⬇️ *Final UI Output*  
![Final Output](https://github.com/user-attachments/assets/d5b40640-e427-4e38-b26e-dcf231b05590)

---

## 🧪 How to Run Locally

```bash
git clone <repository-url>
cd <repository-directory>
```

Create `.env` file:
```bash
echo "DATABASE_HOST=db" > .env
echo "DATABASE_NAME=test_db" >> .env
echo "DATABASE_USER=root" >> .env
echo "DATABASE_PASSWORD=root" >> .env
echo "DATABASE_PORT=3306" >> .env
```

Start services:
```bash
docker-compose -f docker-compose.yml up -d
```

App will be available at: `http://localhost:80`

To stop and clean up:
```bash
docker-compose -f docker-compose.yml down --volumes
```

---

## 📝 Notes

- **Staging** deploys automatically on `main` updates.
- **Production** deploys manually via GitHub Actions.
- GitHub Actions pipeline **ignores** changes to:
  - `README.md`
  - `kustomization.yaml`
  - `k8s-manifests-for-github-action/README.md`
- Required GitHub secrets:
  - `DOCKER_USERNAME`
  - `DOCKER_PASS`
  - `GIT_TOKEN`
  - `KUBECONFIG`

---
