#!/usr/bin/env bash
# Usage:
#   ./scripts/cleanup.sh <RAW_BUCKET> <PROCESSED_BUCKET> <ATHENA_RESULTS_BUCKET> [REGION]
#
# Example:
#   ./scripts/cleanup.sh \
#     123456789012-data-pipeline-raw-us-west-1 \
#     123456789012-data-pipeline-processed-us-west-1 \
#     123456789012-data-pipeline-athena-results-us-west-1 \
#     us-west-1

set -euo pipefail

RAW_BUCKET=${1:?raw bucket required}
PROC_BUCKET=${2:?processed bucket required}
RES_BUCKET=${3:?athena results bucket required}
REGION=${4:-us-west-1}

echo "Region: ${REGION}"
echo "Raw bucket:        ${RAW_BUCKET}"
echo "Processed bucket:  ${PROC_BUCKET}"
echo "Athena results:    ${RES_BUCKET}"
echo

read -r -p "Proceed with deleting ALL objects and buckets? [y/N] " confirm
if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

echo "Deleting S3 objects (raw, processed, athena-results)..."
aws s3 rm "s3://${RAW_BUCKET}" --recursive --region "${REGION}" || true
aws s3 rm "s3://${PROC_BUCKET}" --recursive --region "${REGION}" || true
aws s3 rm "s3://${RES_BUCKET}" --recursive --region "${REGION}" || true

echo "Attempting to remove buckets..."
aws s3 rb "s3://${RAW_BUCKET}" --force --region "${REGION}" || true
aws s3 rb "s3://${PROC_BUCKET}" --force --region "${REGION}" || true
aws s3 rb "s3://${RES_BUCKET}" --force --region "${REGION}" || true

echo "Cleanup script completed."
echo "Note: Glue databases/tables and IAM roles are NOT deleted by this script."
