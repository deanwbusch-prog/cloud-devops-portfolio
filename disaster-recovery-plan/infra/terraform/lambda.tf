variable "lambda_backup_trigger_name" {
  description = "Name of the backup trigger Lambda function."
  type        = string
  default     = "dr-backup-trigger"
}

variable "lambda_verify_backup_name" {
  description = "Name of the verify backup Lambda function."
  type        = string
  default     = "dr-verify-backup"
}

# IAM role for Lambda execution
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "dr-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Basic execution + AWS Backup permissions (similar to iam/lambda-backup-policy.json)
data "aws_iam_policy_document" "lambda_execution_policy" {
  statement {
    sid    = "Logs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "BackupJobs"
    effect = "Allow"

    actions = [
      "backup:StartBackupJob",
      "backup:DescribeBackupJob",
      "backup:ListBackupJobs",
      "backup:ListProtectedResources",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "VaultAccess"
    effect = "Allow"

    actions = [
      "backup:ListBackupVaults",
      "backup:ListRecoveryPointsByBackupVault",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name   = "dr-lambda-execution-policy"
  policy = data.aws_iam_policy_document.lambda_execution_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

# Lambda functions
#
# NOTE: these assume you will build ZIPs manually in lambda-scripts/:
#   cd lambda-scripts
#   zip dr-backup-trigger.zip backup_trigger.py
#   zip dr-verify-backup.zip verify_backup.py

resource "aws_lambda_function" "backup_trigger" {
  function_name = var.lambda_backup_trigger_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "backup_trigger.lambda_handler"
  runtime       = "python3.12"

  filename         = "${path.module}/../../lambda-scripts/dr-backup-trigger.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambda-scripts/dr-backup-trigger.zip")

  environment {
    variables = {
      DR_BACKUP_VAULT              = var.backup_vault_name
      BACKUP


