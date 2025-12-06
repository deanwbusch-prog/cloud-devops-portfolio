# Serverless AWS Data Pipeline

This project builds a simple serverless data pipeline on AWS using S3 (raw and processed), Glue (crawler + ETL), and Athena for analytics.

## Prerequisites

- AWS account and IAM user/role with permissions for S3, Glue, Athena, and CloudWatch.
- AWS CLI installed and configured:
  - `aws configure` (set region to `us-east-2` or your chosen region).
- Basic familiarity with SQL (for Athena).

![Architecture Diagram](docs/Data_Pipeline_Architecture.png)

## Repository layout

- `glue-scripts/transform_data.py` – Glue PySpark ETL job.
- `s3-samples/sample_data.csv` – sample orders data.
- `athena-queries/query_example.sql` – Athena DDL and sample query.
- `scripts/cleanup.sh` – deletes lab S3 buckets and objects.
- `infra/cdk/` – AWS CDK (Python) stack for Glue IAM role, database, crawler, and job.

## High-level flow

1. Upload raw CSV to an S3 **raw** bucket.
2. Use a Glue crawler to catalog the CSV into a Glue database and table.
3. Run the Glue job `transform_data.py` to:
   - Cast numeric columns.
   - Normalize `order_date`.
   - Compute `total_price`.
   - Write partitioned Parquet files to a **processed** S3 bucket.
4. Use Athena to create an external table on the processed data and run analytics queries.

## Running the lab (manual steps)

### 1. Create buckets (adjust names and region)

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-2

RAW_BUCKET="${ACCOUNT_ID}-data-pipeline-raw-${REGION}"
PROC_BUCKET="${ACCOUNT_ID}-data-pipeline-processed-${REGION}"
ATHENA_BUCKET="${ACCOUNT_ID}-data-pipeline-athena-results-${REGION}"

aws s3 mb "s3://${RAW_BUCKET}" --region "${REGION}"
aws s3 mb "s3://${PROC_BUCKET}" --region "${REGION}"
aws s3 mb "s3://${ATHENA_BUCKET}" --region "${REGION}"

text

### 2. Upload sample data

aws s3 cp s3-samples/sample_data.csv "s3://${RAW_BUCKET}/raw-data/sample_data.csv"

text

### 3. Glue catalog

- Create a Glue database, for example `data_pipeline_db`.
- Create and run a Glue crawler on `s3://${RAW_BUCKET}/raw-data/`, output to `data_pipeline_db`.

### 4. Glue ETL job

- Create a Glue job using `glue-scripts/transform_data.py`.
- Set job parameters:
  - `--RAW_DATABASE=data_pipeline_db`
  - `--RAW_TABLE=<table-created-by-crawler>`
  - `--PROCESSED_S3_PATH=s3://${PROC_BUCKET}/processed/`
- Run the job and verify Parquet files under `s3://${PROC_BUCKET}/processed/`.

### 5. Athena

- Set query result location to `s3://${ATHENA_BUCKET}/results/`.
- Open `athena-queries/query_example.sql`, replace `<processed-bucket>` with `${PROC_BUCKET}`.
- Run the statements to create the table and the example query.

### 6. Cleanup

./scripts/cleanup.sh "${RAW_BUCKET}" "${PROC_BUCKET}" "${ATHENA_BUCKET}" "${REGION}"

text

## Infrastructure as Code (CDK)

You can provision the Glue role, database, crawler, and job using AWS CDK (Python).

1. Install CDK dependencies:

cd infra/cdk
pip install -r requirements.txt

text

2. Bootstrap the environment (first time per account/region):

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
cdk bootstrap aws://$ACCOUNT_ID/us-east-2

text

3. Deploy the stack:

cd infra/cdk
cdk deploy DataPipelineStack

text

The CDK stack imports the existing S3 buckets by name, then creates the Glue IAM role, Glue database, crawler, and the ETL job wired to `glue-scripts/transform_data.py` stored in the processed bucket.

## CI

A GitHub Actions workflow at `.github/workflows/ci.yml` runs formatting, linting, basic tests, and `cdk synth` on each push to keep the Glue code and CDK stack valid.

## License

This project is released under the MIT License. See the `LICENSE` file for details.
