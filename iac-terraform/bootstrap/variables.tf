variable "region" {
  description = "Region for backend"
  type        = string
  default     = "us-west-1"
}

variable "state_bucket_name" {
  description = "S3 bucket for remote state"
  type        = string
  default     = "iac-terraform-state-CHANGE-ME"
}

variable "lock_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "iac-terraform-locks"
}
