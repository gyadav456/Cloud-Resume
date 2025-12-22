# Cloud Resume Challenge: The "3-in-1" DevOps Portfolio ☁️ 🚀

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Jenkins](https://img.shields.io/badge/jenkins-%232C5263.svg?style=for-the-badge&logo=jenkins&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)

## 📖 Project Overview
This repository is a monorepo that houses **three distinct engineering projects**. 
While they work together to power my portfolio (`gauravyadav.site`), they are architected to demonstrate deep expertise across the entire Cloud/DevOps spectrum.

---

## 🏗️ Project 1: The Serverless Cloud Application
**Role: Cloud Engineer**  
*A highly available, event-driven web application serving a global audience.*

*   **Architecture**: Decoupled Serverless Microservices architecture.
*   **Global Delivery**: Static content hosted on **S3** and distributed via **CloudFront** (CDN) for <50ms latency worldwide.
*   **Backend API**: Python **Lambda** functions handling business logic (Visitor Counter, Gallery API).
*   **Database**: **DynamoDB** (NoSQL) for millisecond-latency data access.
*   **Security**: HTTPS enforcement, API Gateway CORS, and Least-Provilege IAM roles.

---

## 🚀 Project 2: The DevOps Automation Platform
**Role: DevOps Engineer**  
*A "Push-Button" infrastructure platform ensuring Zero-Touch deployment.*

*   **Infrastructure as Code (IaC)**: 100% of the environment (VPC, Instances, DNS, Buckets) is provisioned via **Terraform**.
*   **Immutable CI/CD**: 
    *   **Jenkins** running as a stateless **Docker Container** on EC2.
    *   **Pipelines**: `Jenkinsfile` definitions that automatically build, test, and deploy code on every `git push`.
*   **Lifecycle Automation**: Custom `manage.sh` script to orchestrate the entire stack:
    *   `./manage.sh up` - Provisions all cloud resources.
    *   `./manage.sh down` - Tears down everything to zero cost.

---

## 📊 Project 3: The Observability & Reliability Suite
**Role: Site Reliability Engineer (SRE)**  
*A proactive monitoring system that heals itself and alerts on failure.*

*   **Hybrid Monitoring Stack**:
    *   **CloudWatch**: For serverless metrics (Lambda Invocations, Errors).
    *   **Prometheus & Grafana**: Self-hosted stack tracking infrastructure health.
*   **Chaos Engineering**:
    *   **Chaos Mesh** running on ephemeral K3s to validate resilience (e.g., Pod Kills, Network Latency).
    *   **Reliability Dashboard**: A dedicated `/reliability.html` page transparently showing SLO status and chaos experiment logs.
*   **Active Alerting**:
    *   **SNS** notifications trigger immediately if API Latency > 2s or Error Rate > 0%.
*   **Transparency**: A public `/status.html` page that visualizes real-time system performance.

---


## 🏆 Adherence to DevOps Principles
This system was built strictly adhering to **18 Core DevOps Principles**:

1.  **Automation First**: No manual console clicks.
2.  **Everything as Code**: Infra, Pipelines, and Config are all versioned in Git.
3.  **Fail Fast**: CI pipelines catch errors before deployment.
4.  **Security Built-In**: Secrets management and IAM roles from Day 1.
5.  **Cost Optimization**: Aggressive log retention policies (7 days) and Free Tier usage.

## 📂 Repository Structure (Clean Architecture)

```
├── frontend/             # [Project 1] HTML/CSS/JS (S3 Hosted)
├── backend/              # [Project 1] Python API Code
├── reliability/          # [Project 3] Reliability Service & Chaos Logic
├── infra/                # [Project 2] Terraform Infrastructure (VPC, EKS, EC2)
├── ops/                  # [Project 3] Monitoring Stack (Prometheus/Grafana)
├── pipelines/            # [Project 2] Jenkins & CI/CD Definitions
├── scripts/              # [Automation] Utility scripts (lab management, deployment)
├── Knowledge/            # [Docs] Deep-dive documentation
└── secrets/              # [Ignored] Local keys folder (excluded from git)
```

