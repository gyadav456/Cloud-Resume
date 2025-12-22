#!/bin/bash

# Add Chaos Mesh Repo
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

# Install Chaos Mesh
helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace=chaos-mesh \
  --create-namespace \
  --version 2.6.2 \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/k3s/containerd/containerd.sock

echo "✅ Chaos Mesh Installed"
echo "🌐 Dashboard: http://$(terraform -chdir=infra/k8s_lab output -raw lab_ip):2333"
