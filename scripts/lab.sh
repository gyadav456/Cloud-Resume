#!/bin/bash

# Configuration
LAB_DIR="infra/k8s_lab"
KEY_FILE="$LAB_DIR/lab_key.pem"

function start_lab() {
    echo "🚀 Starting Reliability Lab..."
    cd $LAB_DIR
    terraform init -input=false
    terraform apply -auto-approve
    
    echo "⏳ Waiting for K3s to initialize (30s)..."
    sleep 30
    
    IP=$(terraform output -raw lab_ip)
    echo "✅ Lab Started at $IP"
    echo "🔑 Key location: $KEY_FILE"
    
    # Fetch Kubeconfig
    echo "⬇️ Downloading Kubeconfig..."
    ssh -o StrictHostKeyChecking=no -i lab_key.pem ubuntu@$IP "sudo cat /etc/rancher/k3s/k3s.yaml" > ../../kubeconfig.yaml
    # Replace localhost with remote IP
    sed -i '' "s/127.0.0.1/$IP/g" ../../kubeconfig.yaml
    # Disable TLS Verification for ephemeral IP access
    sed -i '' '/certificate-authority-data:/d' ../../kubeconfig.yaml
    sed -i '' '/server:/i \
    insecure-skip-tls-verify: true' ../../kubeconfig.yaml
    
    echo "🎉 Access Enabled!"
    echo "Run: export KUBECONFIG=$(pwd)/../../kubeconfig.yaml"
    echo "Then: kubectl get nodes"
    cd ../..
}

function stop_lab() {
    echo "🛑 Stopping Reliability Lab..."
    cd $LAB_DIR
    terraform destroy -auto-approve
    rm -f lab_key.pem # Clean up sensitive keys
    cd ../..
    rm -f kubeconfig.yaml
    echo "✅ Lab Destroyed. Cost counter stopped."
}

function connect_lab() {
    cd $LAB_DIR
    IP=$(terraform output -raw lab_ip)
    ssh -i lab_key.pem ubuntu@$IP
    cd ../..
}

case "$1" in
    start)
        start_lab
        ;;
    stop)
        stop_lab
        ;;
    connect)
        connect_lab
        ;;
    *)
        echo "Usage: $0 {start|stop|connect}"
        exit 1
esac
