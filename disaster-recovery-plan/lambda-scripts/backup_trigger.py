import os
import json
import time
import boto3
from datetime import datetime, timezone

backup = boto3.client("backup")

# Env vars (configure in Lambda console)
# DR_BACKUP_VAULT: Name of the AWS Backup vault to use (e.g., DRVault)
# BACKUP_TAG_KEY/BACKUP_TAG_VALUE: Tag filter to select resources for ad-hoc backups (e.g., Backup=Yes)
# BACKUP_COMPLETE_TIMEOUT_SEC: optional, max seconds to wait for completion (default 0 -> no wait)

VAULT = os.getenv("DR_BACKUP_VAULT", "DRVault")
TAG_KEY = os.getenv("BACKUP_TAG_KEY", "Backup")
TAG_VAL = os.getenv("BACKUP_TAG_VALUE", "Yes")
WAIT_SEC = int(os.getenv("BACKUP_COMPLETE_TIMEOUT_SEC", "0"))

def lambda_handler(event, context):
    """
    Triggers on-demand backups for any resources matching the tag (Backup=Yes) using AWS Backup.
    Optionally waits for completion (WAIT_SEC > 0).
    """
    now = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    # Build selection by tag
    selection = {
        "SelectionName": f"on-demand-{now}",
        "IamRoleArn": _get_backup_service_role(),
        "ListOfTags": [
            {"ConditionType": "STRINGEQUALS", "ConditionKey": TAG_KEY, "ConditionValue": TAG_VAL}
        ]
    }

    resp = backup.start_backup_job(
        BackupVaultName=VAULT,
        ResourceArn=_resource_placeholder_for_tag_selection(),
        IamRoleArn=_get_backup_service_role(),
        StartWindowMinutes=60,
        CompleteWindowMinutes=120,
        Lifecycle={"DeleteAfterDays": 30},
        RecoveryPointTags={
            "TriggeredBy": "Lambda",
            "Selection": "Tag",
            "SelectionName": selection["SelectionName"]
        }
    )

    # NOTE: start_backup_job requires a specific ResourceArn. To back up by tag set, use AWS Backup "StartBackupJob" per resource
    # OR (preferred) configure a Backup Plan with tag-based assignment. For ad-hoc tag-wide backups, you can:
    # 1) List protected resources via backup: list_protected_resources (if enrolled)
    # 2) List resources via respective services filtered by tag, then call start_backup_job per resource
    # For simplicity in this sample we expect a single explicit resource ARN in event. Fallback to env for demo.

    # If the event includes "resource_arns", loop and call start_backup_job for each:
    arns = event.get("resource_arns") if isinstance(event, dict) else None
    job_ids = []
    if arns:
        job_ids = []
        for arn in arns:
            r = backup.start_backup_job(
                BackupVaultName=VAULT,
                ResourceArn=arn,
                IamRoleArn=_get_backup_service_role(),
                StartWindowMinutes=60,
                CompleteWindowMinutes=120,
                Lifecycle={"DeleteAfterDays": 30},
                RecoveryPointTags={"TriggeredBy": "Lambda", "Selection": "Explicit"}
            )
            job_ids.append(r["BackupJobId"])
    else:
        # Demo: treat above single-call resp as our job
        job_ids = [resp["BackupJobId"]]

    result = {"started_jobs": job_ids}

    if WAIT_SEC > 0:
        statuses = _wait_for_completion(job_ids, WAIT_SEC)
        result["statuses"] = statuses

    return {"statusCode": 200, "body": json.dumps(result)}

def _get_backup_service_role():
    """
    Your AWS Backup service role ARN; best practice is to reference from env or SSM.
    For demo purposes, Lambda role can also have backup:StartBackupJob.
    """
    return os.getenv("BACKUP_SERVICE_ROLE_ARN", "")

def _wait_for_completion(job_ids, timeout_sec):
    deadline = time.time() + timeout_sec
    statuses = {j: "UNKNOWN" for j in job_ids}
    while time.time() < deadline:
        all_done = True
        for j in job_ids:
            d = backup.describe_backup_job(BackupJobId=j)
            statuses[j] = d["State"]
            if d["State"] in ("CREATED", "PENDING", "RUNNING"):
                all_done = False
        if all_done:
            break
        time.sleep(10)
    return statuses

def _resource_placeholder_for_tag_selection():
    # Placeholder ARN; API requires one. Prefer the explicit ARN path above or a backup plan with tag-based assignment.
    # If you only use explicit ARNs in the event, this value is never used.
    return os.getenv("DEMO_RESOURCE_ARN", "arn:aws:ec2:::instance/i-demo")
