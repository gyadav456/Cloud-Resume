#!/bin/bash

# Add Helm Repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install/Upgrade Stack
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values values.yaml

echo "✅ Monitoring Stack Deployed"
echo "📊 Grafana URL: http://$(terraform -chdir=infra/k8s_lab output -raw lab_ip):30000"
echo "👤 User: admin"
echo "🔑 Pass: admin"
