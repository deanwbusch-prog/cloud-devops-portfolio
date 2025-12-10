variable "backup_schedule_cron" {
  description = "Cron expression for running the backup trigger Lambda."
  type        = string
  default     = "cron(0 9 * * ? *)" # 09:00 UTC (~01:00 us-west-1)
}

variable "verify_schedule_cron" {
  description = "Cron expression for running the verify backup Lambda."
  type        = string
  default     = "cron(0 11 * * ? *)" # 11:00 UTC (~03:00 us-west-1)
}

# EventBridge rule for backup trigger
resource "aws_cloudwatch_event_rule" "backup_schedule" {
  name                = "dr-trigger-daily"
  description         = "Daily trigger for DR backup Lambda"
  schedule_expression = var.backup_schedule_cron
}

resource "aws_cloudwatch_event_target" "backup_schedule_target" {
  rule      = aws_cloudwatch_event_rule.backup_schedule.name
  target_id = "backup-trigger"
  arn       = aws_lambda_function.backup_trigger.arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke_backup" {
  statement_id  = "AllowEventBridgeInvokeBackup"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup_trigger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.backup_schedule.arn
}

# EventBridge rule for verify Lambda
resource "aws_cloudwatch_event_rule" "verify_schedule" {
  name                = "dr-verify-daily"
  description         = "Daily trigger for DR verify Lambda"
  schedule_expression = var.verify_schedule_cron
}

resource "aws_cloudwatch_event_target" "verify_schedule_target" {
  rule      = aws_cloudwatch_event_rule.verify_schedule.name
  target_id = "verify-backup"
  arn       = aws_lambda_function.verify_backup.arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke_verify" {
  statement_id  = "AllowEventBridgeInvokeVerify"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify_backup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.verify_schedule.arn
}


