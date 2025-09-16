#!/usr/bin/env bash
# Usage: ./scripts/cleanup.sh <REGION> <VAULT_NAME> <PLAN_NAME> <TRIGGER_FN> <VERIFY_FN>
set -euo pipefail

REGION=${1:-us-west-1}
VAULT=${2:-DRVault}
PLAN=${3:-DRDailyPlan}
TRIGGER_FN=${4:-dr-backup-trigger}
VERIFY_FN=${5:-dr-verify-backup}

echo "[*] Deleting Lambda functions..."
aws lambda delete-function --function-name "$TRIGGER_FN" --region "$REGION" || true
aws lambda delete-function --function-name "$VERIFY_FN"  --region "$REGION" || true

echo "[*] Deleting EventBridge rules (if any)..."
for R in dr-trigger-daily dr-verify-daily; do
  TARGETS=$(aws events list-targets-by-rule --rule "$R" --region "$REGION" --query 'Targets[].Id' --output text 2>/dev/null || true)
  if [ -n "$TARGETS" ]; then
    aws events remove-targets --rule "$R" --ids $TARGETS --region "$REGION" || true
  fi
  aws events delete-rule --name "$R" --region "$REGION" || true
done

echo "[*] Deleting Backup plan..."
# Find plan id by name
PID=$(aws backup list-backup-plans --region "$REGION" --query "BackupPlansList[?BackupPlanName=='$PLAN'].BackupPlanId" --output text || true)
if [ -n "$PID" ]; then
  aws backup delete-backup-plan --backup-plan-id "$PID" --region "$REGION" || true
fi

echo "[*] (Not deleting vault '$VAULT' or recovery points to avoid data loss)"
echo "[*] Review vault contents manually before removal."
