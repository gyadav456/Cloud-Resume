# 02. Manual Setup Guide (from Scratch)

While the project uses `manage.sh` for one-click automation, this guide explains how to build it manually for learning purposes.

## Prerequisites
1.  **AWS Account**: With Admin access.
2.  **Domain Name**: Purchased via Namecheap/GoDaddy (or Route53).
3.  **Local Tools**:
    *   `terraform` (v1.5+)
    *   `aws-cli` (v2.x)
    *   `git`
    *   `python3`

## Step 1: AWS Configuration
Configure your AWS CLI with credentials that have AdministratorAccess.
```bash
aws configure
# Enter Access Key, Secret Key, Region (us-east-1), Output (json)
```

## Step 2: Terraform Infrastructure
1.  **Clone the Repo**:
    ```bash
    git clone https://github.com/gyadav456/Cloud-Resume.git
    cd Cloud-Resume/infra
    ```
2.  **Initialize Terraform**:
    Downloads providers and configures the backend.
    ```bash
    terraform init
    ```
3.  **Plan the Build**:
    Preview what will be created.
    ```bash
    terraform plan
    ```
4.  **Apply**:
    Provision valid resources (S3, EC2, Lambda, DynamoDB).
    ```bash
    terraform apply -auto-approve
    ```
5.  **Note Outputs**:
    Save the `api_endpoint` and `cloudfront_domain_name`.

## Step 3: Frontend Configuration
1.  **Update API Endpoint**:
    Edit `script.js` and `status.html`. Replace the `API_BASE` variable with your new Terraform output specific URL.
2.  **Upload to S3**:
    ```bash
    aws s3 sync ../ s3://gauravyadav.site --exclude ".git/*" --exclude "infra/*"
    ```
3.  **Invalidate Cache**:
    Force CloudFront to serve new content.
    ```bash
    aws cloudfront create-invalidation --distribution-id <DIST_ID> --paths "/*"
    ```

## Step 4: Jenkins Server (CI/CD)
1.  **Access Server**:
    Get the Public IP from AWS Console or Terraform output.
    Key is stored in AWS Secrets Manager (`jenkins-key`).
2.  **Bypass Manual Install**:
    Since we use Docker, Jenkins starts automatically via `user_data`.
3.  **Unlock Jenkins**:
    SSH into the server:
    ```bash
    ssh -i key.pem ubuntu@<IP>
    docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
    ```
4.  **Configure Pipeline**:
    *   New Item -> Pipeline -> "Cloud-Resume-Backend".
    *   SCM -> Git -> Repository URL.
    *   Script Path -> `Jenkinsfile.backend`.

## Step 5: Observability Stack
1.  **SSH into Server**:
    ```bash
    ssh -i key.pem ubuntu@<IP>
    ```
2.  **Start Stack**:
    ```bash
    cd Cloud-Resume/ops
    sudo docker compose up -d
    ```
3.  **Access Grafana**:
    Open browser: `http://<IP>:3000` (User: admin/admin).

## Step 6: Verification
*   Visit `https://gauravyadav.site`.
*   Check `https://gauravyadav.site/status.html`.
*   Check Jenkins Build History.
