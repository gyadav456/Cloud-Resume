terraform {
  backend "s3" {
    bucket = "gyadav-terraform-state-backend"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --- DynamoDB Table ---
resource "aws_dynamodb_table" "visitor_counter" {
  name           = "VisitorCounter"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project = "CloudResume"
  }
}

# --- Lambda Function ---

# Archive the python code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "resume_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach basic execution policy (logs)
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach DynamoDB access policy
# Attach DynamoDB access policy
resource "aws_iam_policy" "dynamodb_access" {
  name        = "ResumeDynamoDBAccess"
  description = "Allow Lambda to read/write to VisitorCounter table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.visitor_counter.arn
      }
    ]
  })
}

# Attach S3 List access policy
resource "aws_iam_policy" "s3_list_access" {
  name        = "ResumeS3ListAccess"
  description = "Allow Lambda to list objects in the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::gauravyadav.site"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dynamodb_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.s3_list_access.arn
}

resource "aws_iam_policy" "cw_access" {
  name        = "ResumeCloudWatchAccess"
  description = "Allow Lambda to get metrics from CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:GetMetricStatistics"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_cw_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.cw_access.arn
}

resource "aws_lambda_function" "visitor_counter_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "VisitorCounterFunction"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.visitor_counter.name
      BUCKET_NAME = "gauravyadav.site"
    }
  }
}

# --- API Gateway (HTTP API) ---
resource "aws_apigatewayv2_api" "http_api" {
  name          = "ResumeAPI"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# Integration with Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.visitor_counter_lambda.invoke_arn
  payload_format_version = "2.0"
}

# Route for POST /visitor
resource "aws_apigatewayv2_route" "visitor_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /visitor"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route for GET /gallery
resource "aws_apigatewayv2_route" "gallery_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /gallery"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route for GET /metrics
resource "aws_apigatewayv2_route" "metrics_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /metrics"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*/*"
}

# Output the API Endpoint
output "api_endpoint" {
  value = "${aws_apigatewayv2_api.http_api.api_endpoint}/visitor"
}

# --- ACM Certificate (HTTPS Step 1) ---
resource "aws_acm_certificate" "site_cert" {
  domain_name       = "gauravyadav.site"
  validation_method = "DNS"

  subject_alternative_names = ["www.gauravyadav.site"]

  tags = {
    Project = "CloudResume"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "acm_certificate_validation_records" {
  value = {
    for dvo in aws_acm_certificate.site_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
}

# --- CloudFront (HTTPS Step 2) ---

resource "aws_acm_certificate_validation" "site_cert_validation" {
  certificate_arn         = aws_acm_certificate.site_cert.arn
  validation_record_fqdns = [for record in aws_acm_certificate.site_cert.domain_validation_options : record.resource_record_name]
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "gauravyadav.site.s3-website.ap-south-1.amazonaws.com"
    origin_id   = "S3-gauravyadav.site"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["gauravyadav.site", "www.gauravyadav.site"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-gauravyadav.site"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100" # Use only North America and Europe for cheaper cost

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site_cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}
