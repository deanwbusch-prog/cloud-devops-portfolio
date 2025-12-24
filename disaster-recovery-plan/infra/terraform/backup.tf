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

    # Daily at 09:00 UTC (adjust as needed)
    schedule = "cron(0 9 * * ? *)"

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
