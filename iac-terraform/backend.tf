# After running ./bootstrap, fill these, then run: terraform init -migrate-state
terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_BOOTSTRAP_BUCKET"
    key            = "iac-terraform/terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "REPLACE_WITH_BOOTSTRAP_LOCK_TABLE"
    encrypt        = true
  }
}
