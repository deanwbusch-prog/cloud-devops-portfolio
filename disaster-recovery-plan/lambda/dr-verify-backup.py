import os
import json
import boto3
from datetime import datetime, timedelta, timezone

backup = boto3.client("backup")

VAULT = os.getenv("DR_BACKUP_VAULT", "DRVault")
LOOKBACK_HOURS = int(os.getenv("LOOKBACK_HOURS", "26"))  # check last backup window

def lambda_handler(event, context):
    """
    Verifies that at least one successful backup completed in the last LOOKBACK_HOURS.
    Optionally filter by ResourceArn if provided in the event.
    """
    since = datetime.now(timezone.utc) - timedelta(hours=LOOKBACK_HOURS)
    resource_arn = (event or {}).get("resource_arn")

    # List jobs in time window
    jobs = []
    next_token = None
    while True:
        kwargs = {"ByCreatedAfter": since}
        if next_token:
            kwargs["NextToken"] = next_token
        resp = backup.list_backup_jobs(**kwargs)
        jobs.extend(resp.get("BackupJobs", []))
        next_token = resp.get("NextToken")
        if not next_token:
            break

    # Filter to this vault and (optional) resource
    filtered = [
        j for j in jobs
        if j.get("BackupVaultName") == VAULT and
           (not resource_arn or j.get("ResourceArn") == resource_arn)
    ]

    latest = sorted(filtered, key=lambda x: x.get("CreationDate", datetime.min), reverse=True)

    ok = any(j.get("State") == "COMPLETED" for j in latest)
    status = {
        "checked_jobs": len(latest),
        "ok": ok,
        "latest_states": [
            {"id": j["BackupJobId"], "state": j["State"], "resource": j.get("ResourceArn")}
            for j in latest[:10]
        ]
    }

    return {"statusCode": 200, "body": json.dumps(status)}
