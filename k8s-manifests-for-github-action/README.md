
# Django-Note-App Kubernetes Deployment

This repository contains the necessary Kubernetes manifests and scripts to set up RBAC (Role-Based Access Control) and authentication for deploying the Django-Note-App to a cloud Kubernetes (K8s) cluster using GitHub Actions and ArgoCD. Before deploying to staging or production environments, we configure GitHub Actions with appropriate access to the Kubernetes cluster using a ServiceAccount, kubeconfig file, and ArgoCD integration for GitOps workflows.

## Prerequisites
- A Kubernetes cluster running in the cloud.
- `kubectl` installed and configured to communicate with your cluster.
- A GitHub repository with Actions enabled.
- An ArgoCD instance running in the cluster (e.g., in the `argocd` namespace).

## GitHub Actions Access Setup
To enable GitHub Actions to deploy to the Kubernetes cluster (e.g., staging or production) and manage ArgoCD applications, we use a ServiceAccount with specific permissions. The following files in the `k8s-manifests-for-github-action` directory configure this access:

### Files and Their Purpose

1. **`django-note-app-sa.yaml`**
   - **Purpose**: Defines a ServiceAccount named `django-note-app-deployer` in the `django-note-app` namespace.
   - **Details**: This ServiceAccount is used by GitHub Actions to authenticate and interact with the Kubernetes cluster. It acts as an identity for automated processes, ensuring they have the necessary permissions to deploy resources.

2. **`django-note-app-role.yaml`**
   - **Purpose**: Specifies a Role named `django-note-app-role` with a set of permissions.
   - **Details**: This Role defines what actions the ServiceAccount can perform within the `django-note-app` namespace. It includes permissions to manage pods, services, deployments, and ingresses (e.g., `get`, `list`, `watch`, `create`, `update`, `patch`, `delete`), limiting the ServiceAccount’s scope to what’s necessary for deployment.

3. **`django-note-app-rb.yaml`**
   - **Purpose**: Creates a RoleBinding named `django-note-app-rb` to link the ServiceAccount to the Role.
   - **Details**: This binds the `django-note-app-deployer` ServiceAccount to the `django-note-app-role`, granting it the permissions defined in the Role. Without this binding, the ServiceAccount would have no specific privileges in the `django-note-app` namespace.

4. **`django-note-app-secret.yaml`**
   - **Purpose**: Defines a Secret named `django-note-app-deployer-token` associated with the ServiceAccount.
   - **Details**: This Secret automatically generates a token for the ServiceAccount, which is used for authentication when communicating with the Kubernetes API. The token is critical for generating the kubeconfig file used by GitHub Actions.

5. **`argocd-app-manager-role.yaml`**
   - **Purpose**: Specifies a Role named `argocd-app-manager` with permissions for ArgoCD applications.
   - **Details**: This Role, defined in the `argocd` namespace, grants permissions to manage ArgoCD `applications` resources (e.g., `get`, `list`, `watch`, `create`, `update`, `patch`, `delete`). It allows the ServiceAccount to interact with ArgoCD-specific resources in the `argocd` namespace.

6. **`argocd-app-access-binding.yaml`**
   - **Purpose**: Creates a RoleBinding named `argocd-app-access-binding` to link the ServiceAccount to the ArgoCD Role.
   - **Details**: This binds the `django-note-app-deployer` ServiceAccount (from the `django-note-app` namespace) to the `argocd-app-manager` Role in the `argocd` namespace, enabling cross-namespace permissions for ArgoCD application management.

### Kustomize Configuration
- The `k8s-manifests-for-github-action/kustomization.yaml` file ties these resources together:
  ```yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization
  namespace: django-note-app
  resources:
    - django-note-app-sa.yaml
    - django-note-app-role.yaml
    - django-note-app-rb.yaml
    - django-note-app-secret.yaml
    - argocd-app-manager-role.yaml
    - argocd-app-access-binding.yaml
  ```
- Note: The `namespace` field in `kustomization.yaml` applies to resources without an explicit namespace, but `argocd-app-manager-role.yaml` and `argocd-app-access-binding.yaml` explicitly specify the `argocd` namespace, so they remain unaffected.

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
In your GitHub Actions workflow (e.g., `.github/workflows/gitops-argocd.yaml`), you can use the `KUBECONFIG` secret to authenticate with the Kubernetes cluster and deploy resources managed by ArgoCD. Example snippet:
```yaml
name: Deploy Django-Note-App with ArgoCD
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Kubeconfig
        env:
          KUBECONFIG: ${{ secrets.KUBECONFIG }}
        run: |
          echo "$KUBECONFIG" > kubeconfig.yaml
      - name: Deploy to Kubernetes
        run: |
          kubectl apply -k kubernetes-manifests/base --kubeconfig=kubeconfig.yaml
```

## Workflow with ArgoCD
1. **Apply RBAC Configuration**:
   - Ensure the `django-note-app` and `argocd` namespaces exist:
     ```bash
     kubectl create namespace django-note-app
     kubectl create namespace argocd
     ```
   - Apply the RBAC manifests:
     ```bash
     kubectl apply -k k8s-manifests-for-github-action/
     ```

2. **Deploy Application**:
   - The GitHub Actions workflow applies manifests in `kubernetes-manifests/base`, which should include ArgoCD Application resources.
   - The `django-note-app-deployer` ServiceAccount uses its permissions from both `django-note-app-role` (for the `django-note-app` namespace) and `argocd-app-manager` (for the `argocd` namespace) to manage resources and sync ArgoCD applications.

## Notes
- **Namespace Separation**: The `django-note-app-role` applies to the `django-note-app` namespace for application resources, while `argocd-app-manager-role` applies to the `argocd` namespace for ArgoCD-specific management. This setup allows the ServiceAccount to operate across both namespaces.
- **Pre-Deployment Setup**: Ensure the Kubernetes cluster has both the `django-note-app` and `argocd` namespaces created and an ArgoCD instance running before applying manifests.
- **Applying Manifests**: Use Kustomize to apply application manifests:
  ```bash
  kubectl apply -k kubernetes-manifests/base
  ```
- **Security**: The generated `kubeconfig-django-note-app.yaml` file is excluded from version control via `.gitignore` to prevent exposing sensitive credentials.
- **Testing**: Test the RBAC setup locally with `kubectl`:
  - For `django-note-app` namespace: `kubectl auth can-i create pods --as=system:serviceaccount:django-note-app:django-note-app-deployer -n django-note-app`
  - For `argocd` namespace: `kubectl auth can-i create applications.argoproj.io --as=system:serviceaccount:django-note-app:django-note-app-deployer -n argocd`

This setup provides secure, limited access for GitHub Actions to deploy the Django-Note-App to your Kubernetes cluster using ArgoCD for GitOps automation.

---

### Key Changes
1. **Added New Files**: Included `argocd-app-manager-role.yaml` and `argocd-app-access-binding.yaml` as separate entries, keeping the original configuration intact in the `argocd` namespace.
2. **Updated Kustomization**: Provided an example `kustomization.yaml` to include the new files.
3. **Workflow Clarification**: Explained how the ServiceAccount uses permissions across both namespaces.
4. **Notes**: Added details about namespace separation and testing commands for both namespaces.

This updated `README.md` now accurately reflects the addition of the provided RBAC configuration as distinct files. Let me know if you need further adjustments!
