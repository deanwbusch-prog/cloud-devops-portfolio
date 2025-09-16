variable "project" {
  description = "Project name prefix"
  type        = string
  default     = "iac-terraform"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (2 AZs)"
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.20.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (2 AZs)"
  type        = list(string)
  default     = ["10.20.30.0/24", "10.20.40.0/24"]
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to EC2"
  type        = string
  default     = "0.0.0.0/0" # CHANGE in terraform.tfvars to your IP/32
}

variable "key_name" {
  description = "EC2 key pair name in this region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch"
  type        = bool
  default     = false
}
