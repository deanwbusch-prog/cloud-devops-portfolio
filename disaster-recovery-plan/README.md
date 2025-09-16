# AWS Disaster Recovery Plan (Manual Build)

A hands-on Disaster Recovery (DR) setup built **manually** so you understand every piece:
- **AWS Backup** plans + vault (daily, 30-day retention by default)
- **S3 Versioning** for object protection
- **Lambda automation** to trigger standardized backups and verify job status
- **CloudWatch / EventBridge** rules for schedules + alerts
- **Athena/CloudTrail** optional for audit

---

## Architecture

![Architecture](docs/Disaster_Recovery_Architecture.png)

**Flow**
1) **AWS Backup** runs policies on tagged resources (EC2, EBS, RDS, DynamoDB, EFS).  
2) **S3 Versioning** protects object data against delete/overwrite.  
3) **Lambda** (EventBridge scheduled) triggers ad-hoc backups and verifies job success; can notify on failure.  
4) **CloudWatch** logs/alarms for Backup jobs + Lambda.

**Core AWS**: AWS Backup, S3, Lambda, EventBridge (CloudWatch Events), IAM, CloudWatch Logs.

---

## Region & Names
Default region: **us-west-1**  
Vault name: `DRVault`  
Plan name: `DRDailyPlan`

---

## Quick Start (high level)

1. **Enable S3 versioning** on your critical buckets.  
2. **Create AWS Backup** vault + plan (daily rule, retention 30 days).  
3. **Create IAM role** for Lambda (least-privilege JSON included).  
4. **Deploy Lambda** functions (`backup_trigger.py`, `verify_backup.py`).  
5. **Create EventBridge rules** to:  
   - run `dr-backup-trigger` on a schedule (e.g., daily at 01:00)  
   - run `dr-verify-backup` after backup windows (optional)  
6. **Test recovery** (S3 version restore + AWS Backup restore job).  
7. **Export diagram** with AWS Perspective → `docs/Disaster_Recovery_Architecture.png`.

---

## Clean Up

```bash
./scripts/cleanup.sh us-west-1 DRVault DRDailyPlan dr-backup-trigger dr-verify-backup
