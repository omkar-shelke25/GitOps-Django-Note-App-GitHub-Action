#!/bin/bash
SECRET_NAME=django-note-app-deployer-token
TOKEN=$(kubectl -n django-note-app get secret $SECRET_NAME -o jsonpath="{.data.token}" | base64 -d)
CA=$(kubectl -n django-note-app get secret $SECRET_NAME -o jsonpath="{.data['ca\.crt']}")
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

cat <<EOF > kubeconfig-django-note-app.yaml
apiVersion: v1
kind: Config
clusters:
- name: django-note-app-cluster
  cluster:
    certificate-authority-data: $CA
    server: $SERVER
contexts:
- name: django-note-app-context
  context:
    cluster: django-note-app-cluster
    user: django-note-app-user
current-context: django-note-app-context
users:
- name: django-note-app-user
  user:
    token: $TOKEN
EOF