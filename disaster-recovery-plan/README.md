# AWS Disaster Recovery Plan (Terraform + AWS Backup)

AWS Disaster Recovery setup built around AWS Backup, Lambda, and EventBridge in a single region. The design uses tag-based policies, scheduled backups, and simple verification to mirror how real teams protect workloads in production.

- Region: `us-west-1`  
- Backup vault: `DRVault`  
- Backup plan: `DRDailyPlan`  

---

## Architecture

AWS Backup takes daily backups of tagged resources into a dedicated vault, while EventBridge-scheduled Lambdas initiate and verify backups and send logs to CloudWatch.

- AWS Backup vault stores recovery points for supported services in `us-west-1`.  
- Backup plan defines schedule and retention and uses tag-based resource assignment (for example, `Backup=Yes`).  
- EventBridge rules invoke Lambda functions on a schedule, and CloudWatch Logs capture all activity for audit.  

### Diagram

![Architecture](docs/Disaster_Recovery_Architecture.png) shows how AWS Backup, EventBridge, Lambda, and CloudWatch interact for scheduled backups and verification.

---

## Components

- **AWS Backup**  
  - Backup vault `DRVault` in `us-west-1` to store recovery points.  
  - Backup plan `DRDailyPlan` with a daily schedule and retention (for example, 30 days).  
  - Tag-based resource selection so any supported resource with `Backup=Yes` is included automatically.  

- **Lambda functions**  
  - `dr-backup-trigger` (optional): can start on-demand backup jobs for tagged resources or specific ARNs.  
  - `dr-verify-backup`: checks recent AWS Backup jobs and reports whether at least one backup completed successfully in the last window.  

- **EventBridge and CloudWatch**  
  - EventBridge rules run the trigger and verify Lambdas on a cron schedule.  
  - CloudWatch Logs store Lambda output and backup job logs for troubleshooting and compliance.  

---

## How backups are selected

Resources are enrolled in the backup plan by tag instead of hard-coding ARNs, which keeps the DR policy simple and scalable.

- Add a tag such as `Backup=Yes` to EC2 instances, EBS volumes, RDS databases, or other supported services.  
- The backup plan’s resource assignment finds resources with that tag in `us-west-1` and includes them in the daily schedule automatically.  

---

## Deploy with Terraform

Terraform is used to create the backup vault, backup plan, tag-based selection, IAM roles, Lambda functions, and EventBridge rules as code.

1. Change into the Terraform directory (for example):  
cd infra/terraform

text
2. Initialize and apply the configuration:  
terraform init
terraform apply

text
3. In the AWS Backup console, confirm that `DRVault`, `DRDailyPlan`, and a tag-based resource assignment exist in `us-west-1`.  

---

## Using the system

Day-to-day DR management is driven by tags and schedules rather than manual jobs.

- Tag any resource you want protected with `Backup=Yes`.  
- Let the backup plan run on its daily schedule, or start an on-demand backup from the AWS Backup console when needed.  
- After the backup window, check the `dr-verify-backup` Lambda logs in CloudWatch to see whether recent jobs succeeded.  

For demos or runbooks:

- Show that adding or removing the `Backup=Yes` tag automatically enrolls or removes a resource from the plan.  
- Show how `dr-verify-backup` reports failure if no successful jobs are detected in the last backup window, and what actions an engineer would take next.  

---

## Cleanup

To remove the DR environment safely:

- Ensure you no longer need the recovery points stored in `DRVault`.  
- From the Terraform directory, run:  
terraform destroy

text
- AWS Backup vaults can only be deleted when empty or when retention constraints are explicitly overridden.  

---

## License

MIT.
