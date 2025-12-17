# Jenkins Initial Setup Guide

Your Jenkins server is live! Here is how to unlock and configure it.

## 1. Access the Server
- **URL**: [http://50.19.140.88:8080](http://50.19.140.88:8080)
- **Status**: It might take 2-3 minutes to become reachable after creation.

## 2. Get the Admin Password
You need to SSH into the server to retrieve the initial password.
Run this command from your terminal:
```bash
chmod 400 infra/jenkins-key.pem
ssh -i infra/jenkins-key.pem ubuntu@50.19.140.88 "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
```
**Admin Password**: `55a938006eba4292a9d5b48294f7643a` (I fetched this for you)

## 3. Configure Jenkins
1.  Paste the password in the Jenkins URL.
2.  Click **"Install suggested plugins"**.
3.  Create your first **Admin User** (Username/Password).
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
