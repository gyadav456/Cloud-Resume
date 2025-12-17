# --- Security Group for Jenkins ---
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-security-group"
  description = "Allow Port 22 and 8080"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

# --- SSH Key Pair ---
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "jenkins-key"
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

resource "aws_secretsmanager_secret" "jenkins_secret_key" {
  name        = "jenkins_server_private_key_v2" # v2 to ensure uniqueness if v1 exists
  description = "Private key for Jenkins Server"
  recovery_window_in_days = 0 
}

resource "aws_secretsmanager_secret_version" "jenkins_secret_key_val" {
  secret_id     = aws_secretsmanager_secret.jenkins_secret_key.id
  secret_string = tls_private_key.jenkins_key.private_key_pem
}

# --- EC2 Instance ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jenkins_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name
  security_groups = [aws_security_group.jenkins_sg.name]

  # IAM Role for Requesting Certs/Deploying (Giving it Admin for simplicity in this demo context)
  # Ideally, we should scope this down.
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              # 1. Update and Swap Setup (Crucial for t2.micro)
              apt-get update -y
              fallocate -l 2G /swapfile
              chmod 600 /swapfile
              mkswap /swapfile
              swapon /swapfile
              echo '/swapfile none swap sw 0 0' >> /etc/fstab

              # 2. Install Docker & Build Tools
              apt-get update -y
              apt-get install -y ca-certificates curl gnupg lsb-release
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

              # 3. Configure Docker Permissions
              usermod -aG docker ubuntu
              chmod 666 /var/run/docker.sock

              # 4. Run Jenkins in Docker
              docker run -d \
                --name jenkins \
                --restart always \
                -p 8080:8080 -p 50000:50000 \
                -v jenkins_home:/var/jenkins_home \
                -v /var/run/docker.sock:/var/run/docker.sock \
                jenkins/jenkins:lts-jdk17

              # 5. Tools
              apt-get install -y unzip python3-pip git
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              EOF

  tags = {
    Name = "Jenkins-Server"
  }
}

# --- IAM Role for Jenkins Instance ---
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins_server_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "jenkins_policy" {
  name        = "jenkins_ci_policy"
  description = "Policy for Jenkins CI/CD to manage infrastructure"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "dynamodb:*",
          "lambda:*",
          "apigateway:*",
          "cloudfront:*",
          "acm:*",
          "route53:*",
          "iam:*",
          "secretsmanager:GetSecretValue",
          "logs:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_policy_attach" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_policy.arn
}

# Note: Ideally, Security Group ingress should be restricted to your specific IP.
# Leaving as 0.0.0.0/0 for demo accessibility, but this violates network isolation best practices.

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins_instance_profile"
  role = aws_iam_role.jenkins_role.name
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins_server.public_ip}:8080"
}
