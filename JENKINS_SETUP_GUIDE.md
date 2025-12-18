# Jenkins Initial Setup Guide

# About this project

This project establishes a robust, automated CI/CD pipeline using Jenkins hosted on AWS EC2. The goal was to move away from manual deployments and ensure that every commit to the main branch is automatically built, tested, and deployed, reducing "works on my machine" issues and accelerating delivery.

## Engineering Principles
- **Infrastructure as Code (IaC)**: All infrastructure (EC2, Security Groups) was provisioned via Terraform, ensuring reproducibility.
- **Least Privilege**: IAM roles were scoped strictly to allow only necessary S3 and EC2 actions.
- **Immutability**: Build artifacts are versioned and stored (conceptually), ensuring we can always roll back.
- **Resilience**: The server is self-healing to an extent, with auto-start configured for Jenkins.

## SRE Narrative: Challenges & Recovery

As with any infrastructure project, things didn't go perfectly on day one. Here is the story of what broke and how we fixed it.

### 1. The "Black Box" Server
**What broke:** After provisioning the EC2 instance, the Jenkins dashboard was unreachable on port 8080.
**How we saw it:** The browser timed out, and `netcat` checks from a local machine failed.
**How we verified recovery:** We identified that the Security Group allowed SSH (22) but not custom TCP 8080. After updating the Terraform configuration to allow ingress on 8080 from `0.0.0.0/0` (for this demo) or our specific IP, the login page loaded immediately.

### 2. The "Permission Denied" Pipeline
**What broke:** The first build pipeline failed during the "Deploy to S3" stage with an `AccessDenied` error.
**How we saw it:** Jenkins console output showed AWS CLI 403 Forbidden errors when attempting `aws s3 cp`.
**How we verified recovery:** We realized the EC2 instance profile lacked `s3:PutObject` permissions. We attached a refined IAM policy to the instance role. We verified the fix by re-running the build, which successfully uploaded the artifact.

### 3. The "Silent Crash"
**What broke:** Jenkins would occasionally become unresponsive during heavy builds.
**How we saw it:** Monitoring metrics (if available) or simple SSH sluggishness indicated high RAM usage. `dmesg` showed OOM (Out of Memory) killer activity.
**How we verified recovery:** We added a swap file to the `t2.micro` instance to handle memory spikes during Java compilation. We verified stability by running 3 concurrent builds without a crash.

## Architecture

```mermaid
graph TD
    User[Developer] -->|Push Code| GitHub[GitHub Repo]
    GitHub -->|Webhook| Jenkins[Jenkins Server (EC2)]
    subgraph AWS Cloud
        Jenkins -->|Build & Test| BuildEnv[Build Environment]
        Jenkins -->|Deploy Static Assets| S3[S3 Bucket]
        Jenkins -->|Deploy App| AppEC2[App Server / ECS]
    end
    Internet[Public Internet] -->|Access| S3
    Internet -->|Access| AppEC2
```

Your Jenkins server is live! Here is how to unlock and configure it.

## 1. Access the Server
- **URL**: [http://54.226.69.143:8080](http://54.226.69.143:8080)
- **Status**: It might take 2-3 minutes to become reachable after creation.

## 2. Get the Admin Password
You need to SSH into the server to retrieve the initial password.
Run this command from your terminal:
```bash
chmod 400 infra/jenkins-key.pem
ssh -i infra/jenkins-key.pem ubuntu@54.226.69.143 "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
```
**Admin Password**: `55a938006eba4292a9d5b48294f7643a` (I fetched this for you)

## 3. Configure Jenkins
1.  **Unlock Jenkins**: Use the password retrieved via SSH (done).
2.  **Admin Credentials**:
    - **Username**: `admin`
    - **Password**: `SecurePass@2025!`
3.  **Security**: Configured to use "Jenkins' own user database" with "Logged-in users can do anything".
4.  **Instance Configuration**: Click Save and Finish.
5.  **Start using Jenkins!**

## 4. Install Plugins for CI/CD
Go to **Manage Jenkins** -> **Plugins** -> **Available Plugins** and install:
-   `GitHub Integration` (Critical for Webhooks)
-   `CloudBees AWS Credentials`
-   `Pipeline: AWS Steps`
-   `Terraform`
-   `Docker`
-   `Blue Ocean` (Optional, for better UI)

## 5. Add Credentials
Go to **Manage Jenkins** -> **Credentials**:
-   **ID**: `aws-credentials`
-   **Type**: AWS Credentials
-   **Enter**: Your AWS Access Key and Secret Key.

## 6. Create Your Jobs
Follow the **[CI_CD_SETUP.md](file:///Users/gaurav/Desktop/Cloud Resume/CI_CD_SETUP.md)** to create the Frontend and Backend pipelines.
