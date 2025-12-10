variable "region" {
  description = "AWS region to deploy the DR resources into."
  type        = string
  default     = "us-west-1"
}

variable "backup_vault_name" {
  description = "Name of the AWS Backup vault."
  type        = string
  default     = "DRVault"
}

variable "backup_plan_name" {
  description = "Name of the AWS Backup plan."
  type        = string
  default     = "DRDailyPlan"
}

variable "backup_tag_key" {
  description = "Tag key used to select resources for backup."
  type        = string
  default     = "Backup"
}

variable "backup_tag_value" {
  description = "Tag value used to select resources for backup."
  type        = string
  default     = "Yes"
}

variable "backup_daily_start_time" {
  description = "Daily backup start time in UTC (HH:MM)."
  type        = string
  default     = "01:00"
}

variable "backup_retention_days" {
  description = "How many days to retain backups."
  type        = number
  default     = 30
}


