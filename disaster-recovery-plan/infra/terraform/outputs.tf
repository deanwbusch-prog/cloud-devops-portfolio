output "backup_vault_name" {
  value       = aws_backup_vault.dr_vault.name
  description = "Name of the backup vault"
}

output "backup_plan_name" {
  value       = aws_backup_plan.dr_plan.name
  description = "Name of the backup plan"
}

output "aws_region" {
  value       = var.aws_region
  description = "AWS region where resources are deployed"
}
