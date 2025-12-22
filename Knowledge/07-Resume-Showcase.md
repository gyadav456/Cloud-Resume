# How to Showcase This Project as 3 Distinct Entries on Your Resume

To maximize the impact of your work, you can split this single mono-repo into **three distinct projects** on your resume. This highlights your versatility across Frontend, DevOps, and SRE domains.

---

## 🏗️ Project 1: Serverless Cloud Web Application
**Role:** Cloud Engineer | **Tech:** AWS Lambda, API Gateway, DynamoDB, S3, CloudFront

*   Architected and deployed a highly available, event-driven web application serving a global audience using **AWS CloudFront** and **S3**.
*   Engineered a **Serverless Backend** with **Python Lambda** functions and **DynamoDB** to handle dynamic visitor tracking and gallery API requests with <50ms latency.
*   Implemented secure REST APIs using **API Gateway** with CORS configuration and least-privilege IAM policies.
*   Designed a responsive, glassmorphism-based UI using intersection observers for high-performance rendering.

---

## 🚀 Project 2: Immutable Infrastructure & CI/CD Platform
**Role:** DevOps Engineer | **Tech:** Terraform, Jenkins, Docker, Bash, GitOps

*   Built a "Push-Button" infrastructure platform (**IaC**) using **Terraform** to provision EC2, VPC, SG, and IAM resources idempotently.
*   Developed a fully Dockerized **Jenkins CI/CD** pipeline, reducing build times by 40% and ensuring environment parity between dev and prod.
*   Authored a `manage.sh` automation suite to handle full-stack lifecycle management (Provision, Deploy, Destroy) with a single command.
*   Enforced security best practices by rotating secrets to **AWS Secrets Manager** and implementing a strict 7-day log retention policy.

---

## 📊 Project 3: Cloud Observability & Reliability Suite
**Role:** Site Reliability Engineer (SRE) | **Tech:** Prometheus, Grafana, CloudWatch, Python, SNS

*   Designed a hybrid monitoring stack integrating **AWS CloudWatch** for serverless metrics and a self-hosted **Prometheus/Grafana** cluster for infrastructure health.
*   Implemented **"Self-Healing" Alerting** using CloudWatch Alarms and SNS to notify admins of 5xx errors or high-latency events within 60 seconds.
*   Developed a custom **Public Status Page** that visualizes real-time system performance (Latency/Traffic) by proxying metrics through a secure Lambda layer.
*   Enhanced error handling with Custom 404/403 pages, improving user experience during edge-case failures.

---

## 💡 Pro-Tip for Interviews
*   **If applying for Dev roles**: Focus on Project 1.
*   **If applying for DevOps roles**: Focus on Project 2.
*   **If applying for SRE roles**: Focus on Project 3.
*   **For General Cloud Roles**: Combine them to show you are a "Full Stack Cloud Engineer" (The "T-Shaped" Developer).
