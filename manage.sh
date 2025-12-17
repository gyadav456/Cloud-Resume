#!/bin/bash
set -e

# Cloud Resume Challenge - Management Script
# Usage: ./manage.sh [up|down|plan|logs]

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function check_deps() {
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Error: terraform is not installed.${NC}"
        exit 1
    fi
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}Error: aws cli is not installed.${NC}"
        exit 1
    fi
}

function deploy() {
    echo -e "${GREEN}🚀 Starting Deployment...${NC}"
    cd infra
    terraform init
    terraform apply -auto-approve
    
    echo -e "${GREEN}✅ Infrastructure Deployed!${NC}"
    API_URL=$(terraform output -raw api_endpoint)
    # SITE_URL=$(terraform output -raw cloudfront_domain_name)
    echo -e "API Endpoint: $API_URL"
    # echo -e "Website: https://$SITE_URL"
    cd ..
}

function destroy() {
    echo -e "${RED}⚠️  WARNING: This will DESTROY all infrastructure!${NC}"
    read -p "Are you sure? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}🔥 Destroying infrastructure...${NC}"
        cd infra
        terraform destroy -auto-approve
        echo -e "${GREEN}✅ Infrastructure Destroyed.${NC}"
        cd ..
    else
        echo "Cancelled."
    fi
}

function logs() {
    echo -e "${GREEN}📋 Tailing Lambda Logs...${NC}"
    aws logs tail /aws/lambda/VisitorCounterFunction --follow
}

check_deps

case "$1" in
    up)
        deploy
        ;;
    down)
        destroy
        ;;
    plan)
        cd infra && terraform plan && cd ..
        ;;
    logs)
        logs
        ;;
    *)
        echo "Usage: $0 {up|down|plan|logs}"
        exit 1
        ;;
esac
