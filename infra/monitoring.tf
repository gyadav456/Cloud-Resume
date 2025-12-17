resource "aws_cloudwatch_dashboard" "resume_dashboard" {
  dashboard_name = "CloudResumeDashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", "VisitorCounter"],
            [".", "ConsumedReadCapacityUnits", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "DynamoDB Capacity"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiName", "ResumeAPI"],
            [".", "Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "API Gateway Latency & Traffic"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "VisitorCounterFunction"],
            [".", "Errors", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Lambda Invocations & Errors"
        }
      }
    ]
  })
}
