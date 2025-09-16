# AWS Data Pipeline (Manual Build, Serverless)

A hands-on, **serverless** data pipeline on AWS that you’ll wire manually to understand each moving part. It ingests raw data to **S3**, transforms it with **AWS Glue (PySpark)**, and queries it with **Amazon Athena**.

---

## Architecture

![Architecture Diagram](docs/Data_Pipeline_Architecture.png)

**Flow**
1) Raw data lands in **S3 (raw)**  
2) **Glue Crawler** catalogs the raw data schema  
3) **Glue Job (PySpark)** cleans/transforms to **Parquet** in **S3 (processed)** (partitioned by `order_date`)  
4) **Athena** runs SQL on processed data in-place (via the Glue Data Catalog)  

**Core AWS**: S3, Glue (Crawler + Job), Athena, IAM, CloudWatch

---

## What’s Included

- Glue ETL script (`glue-scripts/transform_data.py`) — add `total_price`, write Parquet partitioned by `order_date`
- Sample CSV (`s3-samples/sample_data.csv`)
- Athena SQL (`athena-queries/query_example.sql`) to create DB/table and example analytics
- Cleanup script (`scripts/cleanup.sh`)
- AWS Perspective instructions to export a PNG diagram for `docs/`

---

## Region & Buckets

Default region used here: **us-west-1**

You’ll create (unique) buckets like:
- `s3://<account>-data-pipeline-raw-us-west-1`
- `s3://<account>-data-pipeline-processed-us-west-1`
- `s3://<account>-data-pipeline-athena-results-us-west-1`

> Replace `<account>` with something unique (or your AWS account ID).

---

## Quick Start (high-level)

1. Create three S3 buckets (raw, processed, athena results).  
2. Upload `s3-samples/sample_data.csv` to the **raw** bucket.  
3. Create a Glue **database** and **crawler** to catalog the raw CSV.  
4. Create and run the Glue **job** with `glue-scripts/transform_data.py` to write Parquet to **processed**.  
5. In Athena, set results location to the **athena results** bucket and run `athena-queries/query_example.sql`.  
6. Analyze results; export an AWS Perspective PNG to `docs/Data_Pipeline_Architecture.png`.

---

## Clean Up

```bash
./scripts/cleanup.sh <raw-bucket> <processed-bucket> <athena-results-bucket> us-west-1

Security
Least privilege IAM for Glue to only the target buckets + catalog
S3 Block Public Access on all buckets
Encryption at rest (S3 SSE-S3/SSE-KMS) and in transit (HTTPS)
CloudWatch logs for Glue job runs

## License
MIT
