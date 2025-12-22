terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  backend "s3" {
    bucket = "gyadav-terraform-state-backend"
    key    = "infra/k8s_lab.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}
