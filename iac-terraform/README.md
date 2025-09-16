# Infrastructure as Code (IaC) with Terraform — AWS (Manual, Modular)

This project demonstrates **secure, repeatable AWS provisioning** using Terraform, built **piece-by-piece** so you deeply understand each moving part. It includes a remote backend (S3 + DynamoDB locks), modular VPC + EC2, security groups, and optional VPC Flow Logs.

---

## Architecture

![Architecture Diagram](docs/Infrastructure-as-Code_Architecture.png)

**Flow**
1. You write Terraform and commit to GitHub
2. Terraform uses a **remote backend** (S3) with **DynamoDB locks**
3. `terraform plan` previews changes; `terraform apply` provisions infra
4. AWS resources (VPC, subnets, IGW/NAT, route tables, EC2, SGs, S3) come online

**Core Services**: VPC, Subnets, IGW/NAT, Route Tables, EC2, S3 (state), DynamoDB (state lock), IAM (minimal), CloudWatch (Flow Logs optional)

---

## What’s Included

- **Bootstrap stack** (`bootstrap/`) to create S3 bucket + DynamoDB lock table
- **Remote state** configuration (`backend.tf`) wired to that bucket/table
- **Modules**
  - `vpc`: VPC, public/private subnets (multi-AZ), IGW, NAT GW, routes
  - `ec2`: security group + single EC2 instance (Amazon Linux 2023) with user-data
- **Variables** with safe defaults; **tfvars example**
- **AWS Perspective** steps to export the architecture PNG

---

## Quick Start

> Region default is **us-west-1**. Change with `var.region` if needed.

1) **Bootstrap remote state (one-time)**
```bash
cd bootstrap
terraform init
terraform apply -auto-approve
Copy the state_bucket and lock_table outputs.

2.Configure backend
Open backend.tf at repo root and set the bucket/table (see comment markers).
Then:
cd ..
terraform init -migrate-state

3.Plan & Apply (VPC first, then EC2)
# See what will be created
terraform plan
# Apply full stack
terraform apply

4.Outputs
VPC ID, public subnet IDs, EC2 public IP, etc.

5.Destroy (when done)
terraform destroy
Destroy the root stack first, then cd bootstrap && terraform destroy last.

Security
Remote state: versioned, encrypted S3 + DynamoDB locking
Security groups: SSH restricted to allowed_ssh_cidr (your IP)
No hardcoded AMIs: Amazon Linux 2023 resolved dynamically
Workspaces: recommended for dev/test/prod separation

AWS Perspective (Diagram)
Deploy AWS Perspective (AWS Solutions), scan the account/region, and export a PNG of VPC + subnets + routes + EC2. Save as docs/Infrastructure-as-Code_Architecture.png and commit.

Future Enhancements
GitHub Actions CI (fmt/validate/plan)
Private ALB + AutoScaling Groups
SSM Session Manager (no SSH)
Multi-region DR patterns

License
MIT
