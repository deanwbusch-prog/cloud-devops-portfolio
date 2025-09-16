#!/usr/bin/env bash
# Usage: ./scripts/cleanup.sh <RAW_BUCKET> <PROCESSED_BUCKET> <ATHENA_RESULTS_BUCKET> <REGION>
set -euo pipefail

RAW=${1:?raw bucket required}
PROC=${2:?processed bucket required}
RES=${3:?athena results bucket required}
REGION=${4:-us-west-1}

echo "Deleting S3 objects (raw, processed, athena-results)..."
aws s3 rm "s3://$RAW" --recursive --region "$REGION" || true
aws s3 rm "s3://$PROC" --recursive --region "$REGION" || true
aws s3 rm "s3://$RES" --recursive --region "$REGION" || true

echo "Attempting to remove buckets..."
aws s3 rb "s3://$RAW" --force --region "$REGION" || true
aws s3 rb "s3://$PROC" --force --region "$REGION" || true
aws s3 rb "s3://$RES" --force --region "$REGION" || true

echo "Note: Glue databases/tables and IAM roles are not deleted by this script.
