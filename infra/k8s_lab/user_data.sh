#!/bin/bash
curl -sfL https://get.k3s.io | sh -
# Allow default user to access kubeconfig with read access
chmod 644 /etc/rancher/k3s/k3s.yaml
