terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  profile = "disaster-recovery-plan"

  default_tags {
    tags = {
      Project     = "DisasterRecovery"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}
