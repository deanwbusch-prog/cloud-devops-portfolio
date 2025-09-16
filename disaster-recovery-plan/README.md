# AWS Disaster Recovery Plan

## Overview
This project demonstrates how to design and implement a **disaster recovery (DR) strategy** using AWS managed services.  
The goal is to ensure **business continuity**, **high availability**, and **data resilience** by automatically backing up and restoring critical infrastructure and data.

The solution uses AWS Backup, S3 versioning, and AWS Lambda automation to build a reliable disaster recovery workflow that is **scalable**, **cost-effective**, and **secure**.

---

## Architecture
![Architecture Diagram](docs/Disaster_Recovery_Architecture.png)

**Workflow:**
1. **AWS Backup** automatically performs backups of supported AWS services such as EC2, RDS, DynamoDB, and EFS.
2. **Amazon S3 Versioning** protects against accidental file deletion or overwrites.
3. **AWS Lambda** automates custom backup tasks and verifies successful completion.
4. **Amazon CloudWatch** monitors backup jobs and triggers alerts for failures.

---

## AWS Services Used
- **AWS Backup** – Centralized backup management for AWS resources.
- **Amazon S3** – Versioned storage for files and backup data.
- **AWS Lambda** – Automates custom backup and verification tasks.
- **Amazon CloudWatch** – Logs and monitors backup events and system health.
- **AWS IAM** – Manages secure, role-based permissions for DR components.

---

## Tools Used
- **AWS CLI** – Manage and test backups and restores via command line.
- **Python** – Lambda scripts for automation and custom recovery workflows.
- **GitHub** – Version control for Lambda scripts and DR documentation.

---

## Folder Structure
disaster-recovery-plan/
│
├── lambda-scripts/ # Lambda functions for automation
│ └── backup_trigger.py
│
├── docs/
│ └── architecture.png # Architecture diagram
│
├── tests/ # Optional folder for test cases
│ └── restore_test.json
│
└── README.md

---

## Deployment Instructions

### **1. Clone the Repository**
```bash
git clone https://github.com/deanwbusch-prog/disaster-recovery-plan.git
cd disaster-recovery-plan

2. Configure AWS CLI
Set up your AWS CLI for the us-west-1 region:
aws configure
AWS Access Key ID: Your key
AWS Secret Access Key: Your secret
Default region name: us-west-1
Default output format: json

3. Enable S3 Versioning
Enable versioning on your S3 bucket to protect files from accidental deletion or overwrite.
aws s3api put-bucket-versioning \
    --bucket your-bucket-name \
    --versioning-configuration Status=Enabled
Verify:
aws s3api get-bucket-versioning --bucket your-bucket-name

4. Configure AWS Backup
Go to AWS Console → AWS Backup.
Create a Backup Vault to store backups securely.
Define a Backup Plan:
Resources: EC2, RDS, DynamoDB, or other supported services.
Backup Frequency: Daily, weekly, or custom.
Retention Period: Configure based on compliance needs.

5. Deploy Lambda Automation
Deploy the Lambda script for backup automation:
cd lambda-scripts
zip backup_trigger.zip backup_trigger.py
aws lambda create-function \
    --function-name dr-backup-trigger \
    --runtime python3.12 \
    --role arn:aws:iam::<account-id>:role/lambda-execution-role \
    --handler backup_trigger.lambda_handler \
    --zip-file fileb://backup_trigger.zip
Configure CloudWatch Events to trigger the Lambda function on a schedule or after AWS Backup events.

6. Monitoring and Alerts
Use CloudWatch to:
Track backup job success or failure.
Trigger alarms for missed backups or errors.
Send notifications through Amazon SNS or email.

7. Test the Recovery Process
It’s critical to validate your DR plan regularly:
Simulate a failure or deletion event.
Restore data using AWS Backup:
aws backup start-restore-job \
    --recovery-point-arn <arn-of-backup> \
    --resource-type EC2
Verify restored resources are functional and accessible.

8. Clean Up Resources
Delete test backups and temporary resources to avoid ongoing costs:
aws backup delete-backup-vault --backup-vault-name my-test-vault
aws lambda delete-function --function-name dr-backup-trigger

Security Considerations
IAM least privilege: Restrict Lambda and AWS Backup roles to only necessary actions.
Encryption: Enable encryption for S3 buckets and backups using AWS KMS.
Logging and auditing: Use CloudTrail to track backup activities.
Cross-region replication: Store copies in multiple regions for extra resilience.

Future Enhancements
Add multi-region disaster recovery with cross-region S3 replication.
Implement automated failover with Route 53 health checks.
Integrate with AWS CodePipeline for continuous testing of DR workflows.
Add reporting dashboards using Amazon QuickSight.

License
This project is licensed under the MIT License.
