# --- SNS Topic for Alerts ---
resource "aws_sns_topic" "alerts" {
  name = "devops-alerts"
}

# Note: Subscriptions (Email) must be confirmed manually or via separate automation 
# to avoid Terraform waiting indefinitely or spamming.
# We output the ARN so the user can subscribe manually via Console if desired.

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

# --- CloudWatch Alarms ---

# 1. Lambda Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "ResumeLambdaErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Trigger if any Lambda error occurs"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.visitor_counter_lambda.function_name
  }
}

# 2. API Gateway Latency Alarm
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "ResumeAPILatency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = "2000" # 2 Seconds
  alarm_description   = "Trigger if API Latency > 2s"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiName = aws_apigatewayv2_api.http_api.name
  }
}
