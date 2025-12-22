
# --- Networking (Reuse Default VPC/Subnet for Simplicity in Lab) ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security Group ---
resource "aws_security_group" "k8s_lab_sg" {
  name        = "k8s-lab-sg"
  description = "Allow K8s Lab Traffic"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # We will restrict this in production/script if needed, mostly for ease of demo
  }

  # K8s API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP/HTTPS Apps
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePorts
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Key Pair (Generate New for Lab) ---
resource "tls_private_key" "lab_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab_key_pair" {
  key_name   = "k8s-lab-key"
  public_key = tls_private_key.lab_key.public_key_openssh
}

resource "local_file" "lab_key_pem" {
  content  = tls_private_key.lab_key.private_key_pem
  filename = "${path.module}/lab_key.pem"
  file_permission = "0400"
}

# --- EC2 Instance (Spot) ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_subnet" "selected" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-east-1a"
}

resource "aws_instance" "k8s_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  key_name      = aws_key_pair.lab_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.k8s_lab_sg.id]
  subnet_id     = data.aws_subnet.selected.id

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "K8s-Lab-Node"
    Project = "CloudResume-Reliability"
  }
}

output "lab_ip" {
  value = aws_instance.k8s_node.public_ip
}

output "ssh_command" {
  value = "ssh -i infra/k8s_lab/lab_key.pem ubuntu@${aws_instance.k8s_node.public_ip}"
}
