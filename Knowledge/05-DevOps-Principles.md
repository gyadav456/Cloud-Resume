# 05. DevOps Principles Compliance

We architected this solution to adhere strictly to 18 Core DevOps Principles. Here is how:

| # | Principle | Implementation Description |
|---|---|---|
| 1 | **Automation First** | `manage.sh` handles end-to-end provisioning. No manual console clicks allowed. |
| 2 | **Everything as Code** | Infra (`terraform`), Config (`docker-compose`), and Pipelines (`Jenkinsfile`) are versioned. |
| 3 | **CI/CD Default** | Every git push triggers a deployment pipeline. Merging to main = Deploying to Prod. |
| 4 | **Environment Parity** | Docker containers ensure Jenkins & Grafana run identically on dev and prod. |
| 5 | **Reproducible Builds** | Terraform State ensures infrastructure is idempotent. |
| 6 | **Cloud-Native** | Used AWS Lambda (Serverless) instead of EC2 for the app (Scalable, managed). |
| 7 | **Containerization** | Tooling stack (Jenkins, Grafana, Prometheus) is fully Dockerized. |
| 8 | **Scalable Arch** | The website (CloudFront+S3) and API (Lambda) scale infinitely automatically. |
| 9 | **Observability** | Full visibility via Grafana Dashboards and the Public Status Page. |
| 10 | **Health Checks** | CloudWatch Alarms actively monitor system health and alert on failure. |
| 11 | **Security Built-In** | IAM Roles (No keys), Secrets Manager, HTTPS-only, and minimal attack surface. |
| 12 | **Fast Feedback** | SNS Alerts notify admins instantly when errors occur. |
| 13 | **Git as Truth** | The repository *is* the infrastructure. Deleting repo = loss of definition. |
| 14 | **Zero-Downtime** | Lambda deployments are seamless. S3 atomic updates prevented downtime. |
| 15 | **Cost-Aware** | Used Free Tier eligible resources. Set Log retention to 7 days to save money. |
| 16 | **Minimal Intervention** | "Push Button" scripts (`manage.sh`) mean no manual system administration. |
| 17 | **Reliability** | Distributed CDN and Multi-AZ Serverless backend ensure high availability. |
| 18 | **Simple Arch** | Avoided Over-Engineering (e.g., K8s) in favor of simple, effective Serverless patterns. |
