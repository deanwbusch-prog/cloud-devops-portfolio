# AWS Disaster Recovery Plan (Terraform + AWS Backup)

AWS Disaster Recovery setup built around AWS Backup, Lambda, and EventBridge in a single region. The design uses tag-based policies, scheduled backups, and simple verification to mirror how real teams protect workloads in production.[web:100][web:105]

- Region: `us-west-1`  
- Backup vault: `DRVault`  
- Backup plan: `DRDailyPlan`  

---

## Architecture

AWS Backup takes daily backups of tagged resources into a dedicated vault, while EventBridge-scheduled Lambdas initiate and verify backups and send logs to CloudWatch.[web:100][web:105]

- AWS Backup vault stores recovery points for supported services in `us-west-1`.[web:113][web:118]  
- Backup plan defines schedule and retention and uses tag-based resource assignment (for example, `Backup=Yes`).[web:100][web:102]  
- EventBridge rules invoke Lambda functions on a schedule, and CloudWatch Logs capture all activity for audit.[web:105][web:108]  

### Diagram

![Architecture](docs/Disaster_Recovery_Architecture.png) shows how AWS Backup, EventBridge, Lambda, and CloudWatch interact for scheduled backups and verification.[web:105]

---

## Components

- **AWS Backup**  
  - Backup vault `DRVault` in `us-west-1` to store recovery points.[web:110][web:118]  
  - Backup plan `DRDailyPlan` with a daily schedule and retention (for example, 30 days).[web:102][web:116]  
  - Tag-based resource selection so any supported resource with `Backup=Yes` is included automatically.[web:100][web:109]  

- **Lambda functions**  
  - `dr-backup-trigger` (optional): can start on-demand backup jobs for tagged resources or specific ARNs.[web:105]  
  - `dr-verify-backup`: checks recent AWS Backup jobs and reports whether at least one backup completed successfully in the last window.[web:105]  

- **EventBridge and CloudWatch**  
  - EventBridge rules run the trigger and verify Lambdas on a cron schedule.[web:105][web:108]  
  - CloudWatch Logs store Lambda output and backup job logs for troubleshooting and compliance.[web:105][web:114]  

---

## How backups are selected

Resources are enrolled in the backup plan by tag instead of hard-coding ARNs, which keeps the DR policy simple and scalable.[web:100][web:103]

- Add a tag such as `Backup=Yes` to EC2 instances, EBS volumes, RDS databases, or other supported services.  
- The backup plan’s resource assignment finds resources with that tag in `us-west-1` and includes them in the daily schedule automatically.[web:100][web:109]  

---

## Deploy with Terraform

Terraform is used to create the backup vault, backup plan, tag-based selection, IAM roles, Lambda functions, and EventBridge rules as code.[web:102][web:116]

1. Change into the Terraform directory (for example):  
cd infra/terraform

text
2. Initialize and apply the configuration:  
terraform init
terraform apply

text
3. In the AWS Backup console, confirm that `DRVault`, `DRDailyPlan`, and a tag-based resource assignment exist in `us-west-1`.[web:102][web:113]  

---

## Using the system

Day-to-day DR management is driven by tags and schedules rather than manual jobs.[web:100][web:105]

- Tag any resource you want protected with `Backup=Yes`.  
- Let the backup plan run on its daily schedule, or start an on-demand backup from the AWS Backup console when needed.[web:102]  
- After the backup window, check the `dr-verify-backup` Lambda logs in CloudWatch to see whether recent jobs succeeded.[web:105]  

For demos or runbooks:

- Show that adding or removing the `Backup=Yes` tag automatically enrolls or removes a resource from the plan.[web:100][web:109]  
- Show how `dr-verify-backup` reports failure if no successful jobs are detected in the last backup window, and what actions an engineer would take next.[web:105]  

---

## Cleanup

To remove the DR environment safely:[web:113][web:118]

- Ensure you no longer need the recovery points stored in `DRVault`.  
- From the Terraform directory, run:  
terraform destroy

text
- AWS Backup vaults can only be deleted when empty or when retention constraints are explicitly overridden.[web:113][web:118]  

---

## License

MIT.
