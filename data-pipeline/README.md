Serverless AWS Data Pipeline
This project builds a simple serverless data pipeline on AWS using S3 (raw and processed), Glue (crawler + ETL), and Athena for analytics.​

Prerequisites
AWS account and IAM user/role with permissions for S3, Glue, Athena, and CloudWatch.​

AWS CLI installed and configured:

aws configure (set region to us-east-2 or your chosen region).

Basic familiarity with SQL (for Athena).​

![Architecture Diagram](docs/Data_Pipeline_Architecture layout

glue-scripts/transform_data.py – Glue PySpark ETL job.​

s3-samples/sample_data.csv – sample orders data.​

athena-queries/query_example.sql – Athena DDL and sample query.​

scripts/cleanup.sh – deletes lab S3 buckets and objects.​

infra/cdk/ – AWS CDK (Python) stack for Glue IAM role, database, crawler, and job.

High-level flow
Upload raw CSV to an S3 raw bucket.

Use a Glue crawler to catalog the CSV into a Glue database and table.​

Run the Glue job transform_data.py to:

Cast numeric columns.

Normalize order_date.

Compute total_price.

Write partitioned Parquet files to a processed S3 bucket.​

Use Athena to create an external table on the processed data and run analytics queries.​

Running the lab (manual steps)
Create buckets (examples, adjust names and region):

bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-2

RAW_BUCKET="${ACCOUNT_ID}-data-pipeline-raw-${REGION}"
PROC_BUCKET="${ACCOUNT_ID}-data-pipeline-processed-${REGION}"
ATHENA_BUCKET="${ACCOUNT_ID}-data-pipeline-athena-results-${REGION}"

aws s3 mb "s3://${RAW_BUCKET}" --region "${REGION}"
aws s3 mb "s3://${PROC_BUCKET}" --region "${REGION}"
aws s3 mb "s3://${ATHENA_BUCKET}" --region "${REGION}"
Upload sample data:

bash
aws s3 cp s3-samples/sample_data.csv "s3://${RAW_BUCKET}/raw-data/sample_data.csv"
Glue catalog:

Create Glue database, e.g. data_pipeline_db.

Create and run a Glue crawler on s3://${RAW_BUCKET}/raw-data/, output to data_pipeline_db.​

Glue ETL job:

Create a Glue job using glue-scripts/transform_data.py.

Job parameters:

--RAW_DATABASE=data_pipeline_db

--RAW_TABLE=<table-created-by-crawler>

--PROCESSED_S3_PATH=s3://${PROC_BUCKET}/processed/​

Run the job and verify Parquet files under s3://${PROC_BUCKET}/processed/.​

Athena:

Set query result location to s3://${ATHENA_BUCKET}/results/.​

Open athena-queries/query_example.sql, replace <processed-bucket> with ${PROC_BUCKET}.

Run the statements to create the table and the example query.​

Cleanup:

bash
./scripts/cleanup.sh "${RAW_BUCKET}" "${PROC_BUCKET}" "${ATHENA_BUCKET}" "${REGION}"
Infrastructure as Code (CDK)
You can provision the Glue role, database, crawler, and job using AWS CDK (Python).​

Install CDK dependencies:

bash
cd infra/cdk
pip install -r requirements.txt
Bootstrap the environment (first time per account/region):

bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
cdk bootstrap aws://$ACCOUNT_ID/us-east-2
Deploy the stack:

bash
cd infra/cdk
cdk deploy DataPipelineStack
The CDK stack imports the existing S3 buckets by name, then creates the Glue IAM role, Glue database, crawler, and the ETL job wired to glue-scripts/transform_data.py stored in the processed bucket.​

CI
A GitHub Actions workflow (.github/workflows/ci.yml) runs formatting, linting, basic tests, and cdk synth on each push to help keep the Glue code and CDK stack valid.​

License
This project is released under the MIT License. See the LICENSE file for details.
