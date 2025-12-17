# CI/CD Setup Guide

This guide explains how to set up the Jenkins pipelines for your Cloud Resume website and backend.

## Prerequisites
- **Jenkins Server**: Running and accessible.
- **Plugins**: Pipeline, Git, AWS Credentials.
- **Tools on Jenkins Agent**:
  - `terraform`
  - `aws` CLI
  - `python3` and `pip`
  - `git`
- **AWS Credentials**: Configured in Jenkins (ID: `aws-credentials` or managed via IAM role if running on EC2).

## Pipeline 1: Frontend Deployment
This pipeline uploads your website files to the S3 bucket.

1. **Create New Item**: Select "Pipeline" in Jenkins.
2. **Name**: `cloud-resume-frontend`.
3. **Pipeline Definition**: "Pipeline script from SCM".
4. **SCM**: Git (Enter your repository URL).
5. **Script Path**: `Jenkinsfile.frontend`.
6. **Save**.

## Pipeline 2: Backend Deployment
This pipeline tests your Python code and deploys the infrastructure using Terraform.

1. **Create New Item**: Select "Pipeline".
2. **Name**: `cloud-resume-backend`.
3. **Pipeline Definition**: "Pipeline script from SCM".
4. **SCM**: Git.
5. **Script Path**: `Jenkinsfile.backend`.
6. **Save**.

## Webhooks (Automation)
To trigger these pipelines automatically on code push:
1. Go to your Git provider (GitHub/GitLab).
2. Add a Webhook pointing to your Jenkins URL (e.g., `http://jenkins-url/github-webhook/`).
3. In Jenkins jobs, enable "GitHub hook trigger for GITScm polling".

## AWS Configuration check
Ensure your Jenkins user/role has permissions for:
- S3 (PutObject, DeleteObject, ListBucket)
- DynamoDB (Full Access)
- Lambda (Full Access)
- API Gateway (Full Access)
- IAM (PassRole)
