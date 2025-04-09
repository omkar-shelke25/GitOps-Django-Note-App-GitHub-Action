# Django-Note-App Kubernetes Deployment

This repository contains the necessary Kubernetes manifests and scripts to set up RBAC (Role-Based Access Control) and authentication for deploying the Django-Note-App to a cloud Kubernetes (K8s) cluster using GitHub Actions. Before deploying to staging or production environments, we need to configure GitHub Actions with appropriate access to the Kubernetes cluster. This is achieved using a ServiceAccount with specific permissions and a kubeconfig file for authentication.

## Prerequisites
- A Kubernetes cluster running in the cloud.
- `kubectl` installed and configured to communicate with your cluster.
- A GitHub repository with Actions enabled.

## GitHub Actions Access Setup
To enable GitHub Actions to deploy to the Kubernetes cluster (e.g., staging or production), we use a ServiceAccount to define permissions and limitations for interacting with the cluster. The following files in the `k8s-manifests-for-github-action` directory configure this access:

### Files and Their Purpose

1. **`django-note-app-sa.yaml`**
   - **Purpose**: Defines a ServiceAccount named `django-note-app-deployer` in the `django-note-app` namespace.
   - **Details**: This ServiceAccount is used by GitHub Actions to authenticate and interact with the Kubernetes cluster. It acts as an identity for automated processes, ensuring they have the necessary permissions to deploy resources.

2. **`django-note-app-role.yaml`**
   - **Purpose**: Specifies a Role named `django-note-app-role` with a set of permissions.
   - **Details**: This Role defines what actions the ServiceAccount can perform within the `django-note-app` namespace. It includes permissions to manage pods, services, deployments, ingresses, and ArgoCD applications (e.g., `get`, `list`, `create`, `update`, `delete`). This limits the ServiceAccount’s scope to only what’s necessary for deployment.

3. **`django-note-app-rb.yaml`**
   - **Purpose**: Creates a RoleBinding named `django-note-app-rb` to link the ServiceAccount to the Role.
   - **Details**: This binds the `django-note-app-deployer` ServiceAccount to the `django-note-app-role`, granting it the permissions defined in the Role. Without this binding, the ServiceAccount would have no specific privileges.

4. **`django-note-app-secret.yaml`**
   - **Purpose**: Defines a Secret named `django-note-app-deployer-token` associated with the ServiceAccount.
   - **Details**: This Secret automatically generates a token for the ServiceAccount, which is used for authentication when communicating with the Kubernetes API. The token is critical for generating the kubeconfig file used by GitHub Actions.

### Kustomize Configuration
- The `k8s-manifests-for-github-action/kustomization.yaml` file ties these resources together, ensuring they are applied consistently in the `django-note-app` namespace.

## Generating the Kubeconfig File
The `generate-kubeconfig.sh` script generates a `kubeconfig-django-note-app.yaml` file, which contains authentication details for GitHub Actions to access the Kubernetes cluster.

### Steps to Generate and Store the Kubeconfig
1. **Run the Script**:
   ```bash
   cd scripts
   chmod +x generate-kubeconfig.sh
   ./generate-kubeconfig.sh
   ```
   - This creates `kubeconfig-django-note-app.yaml` in the `k8s-manifests-for-github-action/` directory, containing the cluster server details, certificate authority data, and the ServiceAccount token.

2. **Copy the Kubeconfig Content**:
   - Open the generated `kubeconfig-django-note-app.yaml` file and copy its entire contents.

3. **Store in GitHub Repository Secrets**:
   - Go to your GitHub repository: `Settings > Secrets and variables > Actions > Secrets`.
   - Click `New repository secret`.
   - Name the secret (e.g., `KUBECONFIG`).
   - Paste the copied kubeconfig content into the value field and save it.

## Usage in GitHub Actions
In your GitHub Actions workflow (e.g., `.github/workflows/gitops-argocd.yaml`), you can use the `KUBECONFIG` secret to authenticate with the Kubernetes cluster. Example snippet:
```yaml
- name: Deploy to Kubernetes
  env:
    KUBECONFIG: ${{ secrets.KUBECONFIG }}
  run: |
    echo "$KUBECONFIG" > kubeconfig.yaml
    kubectl apply -k kubernetes-manifests/base --kubeconfig=kubeconfig.yaml
```

## Notes
- Ensure the Kubernetes cluster has the `django-note-app` namespace created before applying these manifests:
  ```bash
  kubectl create namespace django-note-app
  ```
- Apply the manifests using Kustomize:
  ```bash
  kubectl apply -k kubernetes-manifests/base
  ```
- The generated `kubeconfig-django-note-app.yaml` file is excluded from version control via `.gitignore` to prevent exposing sensitive credentials.

This setup provides secure, limited access for GitHub Actions to deploy the Django-Note-App to your Kubernetes cluster.

--- 
