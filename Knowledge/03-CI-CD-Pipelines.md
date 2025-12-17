# 03. CI/CD Pipelines Explained

This project uses **Jenkins** for Continuous Integration and Continuous Deployment. The pipeline is defined as code (`Jenkinsfile`) and allows us to deploy confidently on every commit.

## 1. The Build Server
We run Jenkins on an EC2 instance.
*   **Running Mode**: Docker Container (`jenkins/jenkins:lts-jdk17`).
*   **Volume**: `/var/jenkins_home` persisted on host.
*   **Socket**: `/var/run/docker.sock` mounted to allow "Docker-in-Docker" builds.

## 2. Frontend Pipeline (`Jenkinsfile.frontend`)
This pipeline handles the HTML/CSS/JS website.

### Stages
1.  **Checkout**: Pulls code from GitHub.
2.  **Deploy to S3**:
    *   Uses AWS CLI to sync files to `s3://gauravyadav.site`.
    *   Excludes `infra/` and `.git/` to keep the bucket clean.
3.  **Invalidate CDN**:
    *   Clears CloudFront cache so users see updates instantly.

```groovy
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                sh 'aws s3 sync . s3://gauravyadav.site'
                sh 'aws cloudfront create-invalidation ...'
            }
        }
    }
}
```

## 3. Backend Pipeline (`Jenkinsfile.backend`)
This pipeline handles the Python Lambda function and Infrastructure.

### Stages
1.  **Checkout**: Pulls code.
2.  **Test**: Runs Python unit tests (if any).
3.  **Terraform Plan**: Checks infrastructure changes.
4.  **Terraform Apply**:
    *   Zips `lambda_function.py`.
    *   Updates the Lambda code in AWS.
    *   Updates API Gateway configuration if needed.

## 4. Webhooks
*   **Trigger**: GitHub sends a `POST` payload to `http://<JENKINS_IP>:8080/github-webhook/` whenever code is pushed.
*   **Action**: Jenkins matches the repository and branch, then triggers the appropriate job automatically.

## 5. Security in CI/CD
*   **Credentials**: We rely on IAM Roles attached to the EC2 instance ("Instance Profile") rather than hardcoded Access Keys.
*   **Context**: Jenkins assumes the `jenkins_server_role` which grants it permission to run `terraform apply` and write to S3.
