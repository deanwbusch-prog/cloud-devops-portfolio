terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Backup vault
resource "aws_backup_vault" "dr_vault" {
  name = var.backup_vault_name
}

# Backup plan with one daily rule
resource "aws_backup_plan" "dr_plan" {
  name = var.backup_plan_name

  rule {
    rule_name         = "DailyRule"
    target_vault_name = aws_backup_vault.dr_vault.name

    schedule = "cron(0 9 * * ? *)" # 09:00 UTC (~01:00 us-west-1, adjust if needed)

    lifecycle {
      delete_after = var.backup_retention_days
    }
  }
}

# Select resources by tag Backup=Yes
resource "aws_backup_selection" "dr_selection" {
  name         = "TagSelection"
  plan_id      = aws_backup_plan.dr_plan.id
  iam_role_arn = aws_iam_role.backup_service_role.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_tag_key
    value = var.backup_tag_value
  }
}


