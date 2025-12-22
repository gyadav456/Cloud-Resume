# 04. Observability & Monitoring Stack

A production system must be observable. We implemented a hybrid stack using AWS CloudWatch (Serverless Native) and Prometheus/Grafana (Self-Hosted).

## 1. CloudWatch (The Source of Truth)
AWS natively tracks metrics for our Serverless components.
*   **Lambda Metrics**:
    *   `Invocations`: How's traffic?
    *   `Duration`: How fast is it?
    *   `Errors`: Is it failing?
*   **Dashboard**: A Terraform-managed Dashboard (`infra/monitoring.tf`) groups these widgets in the AWS Console.

## 2. Grafana & Prometheus (The Unified View)
We host a customized stack on the Jenkins server using Docker Compose.

### Architecture
*   **Node Exporter**: Running on the EC2 host. Exposes CPU, RAM, Disk I/O metrics.
*   **Prometheus**: Scrapes metrics from Node Exporter (and potentially others).
*   **Grafana**: The visualization layer.
    *   **Data Source 1**: Prometheus (for Infra health).
    *   **Data Source 2**: CloudWatch (for App health).
    *   **Dashboard**: Combines "Server Health" and "App Latency" on one screen.

### Running the Stack
The stack is defined in `ops/docker-compose.yml`.
```bash
docker compose up -d
```

## 3. Public Status Page (`status.html`)
We exposed a slice of this data publicly.
*   **Mechanism**: A "Serverless Proxy".
*   **Flow**: `Browser -> S3 (Page) -> API Gateway -> Lambda -> CloudWatch API`.
*   **Security**: The Lambda has a restricted IAM role (`cloudwatch:GetMetricStatistics`), ensuring no direct database or admin access is exposed.

## 4. Alerting (Self-Healing & Feedback)
We implemented "Active Observability" using CloudWatch Alarms.
*   **Alarm 1**: `ResumeLambdaErrors` (Trigger: Errors > 0).
*   **Alarm 2**: `ResumeAPILatency` (Trigger: Latency > 2s).
*   **Action**: Sends an email via SNS Topic `devops-alerts`.
