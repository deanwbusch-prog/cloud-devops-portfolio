#!/usr/bin/env bash
# Usage: ./scripts/full-cleanup.sh <REGION> <VAULT_NAME> <PLAN_NAME> <TRIGGER_FN> <VERIFY_FN>
set -euo pipefail

REGION=${1:-us-east-2}
VAULT=${2:-DRVault}
PLAN=${3:-DRDailyPlan}
TRIGGER_FN=${4:-dr-backup-trigger}
VERIFY_FN=${5:-dr-verify-backup}

echo "[*] Region: $REGION"
echo "[*] Vault: $VAULT"
echo "[*] Plan:  $PLAN"
echo "[*] Lambdas: $TRIGGER_FN, $VERIFY_FN"
echo
read -p "This will DELETE backup plan, vault, recovery points, Lambdas, and EventBridge rules. Are you sure? (yes/no) " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborting."
  exit 1
fi

echo "[*] Deleting EventBridge rules and targets..."
for R in dr-trigger-daily dr-verify-daily; do
  TARGETS=$(aws events list-targets-by-rule \
    --rule "$R" \
    --region "$REGION" \
    --query 'Targets[].Id' \
    --output text 2>/dev/null || true)

  if [[ -n "${TARGETS:-}" ]]; then
    aws events remove-targets \
      --rule "$R" \
      --ids $TARGETS \
      --region "$REGION" || true
  fi

  aws events delete-rule \
    --name "$R" \
    --region "$REGION" || true
done

echo "[*] Deleting Lambda functions..."
aws lambda delete-function --function-name "$TRIGGER_FN" --region "$REGION" || true
aws lambda delete-function --function-name "$VERIFY_FN"  --region "$REGION" || true

echo "[*] Deleting AWS Backup plan and selections..."
PLAN_ID=$(aws backup list-backup-plans \
  --region "$REGION" \
  --query "BackupPlansList[?BackupPlanName=='$PLAN'].BackupPlanId" \
  --output text 2>/dev/null || true)

if [[ -n "${PLAN_ID:-}" ]]; then
  # Delete selections attached to this plan
  SELECTION_IDS=$(aws backup list-backup-selections \
    --backup-plan-id "$PLAN_ID" \
    --region "$REGION" \
    --query 'BackupSelectionsList[].SelectionId' \
    --output text 2>/dev/null || true)

  if [[ -n "${SELECTION_IDS:-}" ]]; then
    for SID in $SELECTION_IDS; do
      aws backup delete-backup-selection \
        --backup-plan-id "$PLAN_ID" \
        --selection-id "$SID" \
        --region "$REGION" || true
    done
  fi

  aws backup delete-backup-plan \
    --backup-plan-id "$PLAN_ID" \
    --region "$REGION" || true
fi

echo "[*] Deleting ALL recovery points in vault '$VAULT'..."
RP_ARNS=$(aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name "$VAULT" \
  --region "$REGION" \
  --query 'RecoveryPoints[].RecoveryPointArn' \
  --output text 2>/dev/null || true)

if [[ -n "${RP_ARNS:-}" ]]; then
  for RP in $RP_ARNS; do
    aws backup delete-recovery-point \
      --backup-vault-name "$VAULT" \
      --recovery-point-arn "$RP" \
      --region "$REGION" || true
  done
fi

echo "[*] Deleting backup vault '$VAULT'..."
aws backup delete-backup-vault \
  --backup-vault-name "$VAULT" \
  --region "$REGION" || true

echo "[*] Optionally delete IAM role and policy created by Terraform..."
aws iam detach-role-policy \
  --role-name dr-lambda-execution-role \
  --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/dr-lambda-execution-policy \
  --region "$REGION" 2>/dev/null || true

aws iam delete-policy \
  --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/dr-lambda-execution-policy \
  2>/dev/null || true

aws iam delete-role --role-name dr-lambda-execution-role 2>/dev/null || true
aws iam delete-role --role-name AWSBackupDefaultServiceRole 2>/dev/null || true

echo "[*] Full cleanup complete."
