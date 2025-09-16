# AWS Data Pipeline

## Overview
This project builds a **serverless data pipeline on AWS** for ingesting, processing, and analyzing data.  
It demonstrates a modern data engineering workflow that uses AWS managed services to handle:
- **Ingestion** of raw data into Amazon S3
- **Transformation and processing** with AWS Glue
- **Querying and analysis** using Amazon Athena

The pipeline is **cost-effective, scalable, and fully serverless**, making it ideal for cloud-native analytics workloads.

---

## Architecture
![Architecture Diagram](docs/Data_Pipeline_Architecture.png)

**Workflow:**
1. **Data Ingestion** – Raw data is uploaded to the **S3 Raw Bucket**.
2. **ETL Processing** – AWS Glue jobs perform data cleaning, transformation, and structuring.
3. **Processed Storage** – Transformed data is stored in the **S3 Processed Bucket**.
4. **Analytics** – Amazon Athena queries the processed data directly in S3 using serverless SQL.

---

## AWS Services Used
- **Amazon S3** – Scalable, durable storage for both raw and processed data.
- **AWS Glue** – Managed ETL service for data transformation.
- **Amazon Athena** – Serverless SQL query engine for analytics.
- **AWS IAM** – Role-based security for pipeline components.
- **Amazon CloudWatch** – Monitoring, metrics, and alerts.

---

## Tools Used
- **AWS CLI** – Manage S3 and AWS services from the command line.
- **Python or PySpark** – Optional for Glue job scripts.
- **SQL** – Query data using Athena.
- **GitHub** – Version control for Glue job scripts and pipeline definitions.

---

## Folder Structure
data-pipeline/
│
├── glue-scripts/ # Glue ETL scripts
│ └── transform_data.py
│
├── s3-samples/ # Sample raw data for ingestion
│ └── sample_data.csv
│
├── athena-queries/ # Example Athena query scripts
│ └── query_example.sql
│
├── docs/
│ └── architecture.png # Architecture diagram
│
└── README.md

---

## Deployment Instructions

### **1. Clone the Repository**
```bash
git clone https://github.com/deanwbusch-prog/data-pipeline.git
cd data-pipeline

2. Configure AWS CLI
Make sure your AWS CLI is set up for the us-west-1 region:
aws configure
AWS Access Key ID: Your key
AWS Secret Access Key: Your secret
Default region name: us-west-1
Default output format: json

3. Create S3 Buckets
Create two buckets: one for raw data and one for processed data.
aws s3 mb s3://data-pipeline-raw-us-west-1
aws s3 mb s3://data-pipeline-processed-us-west-1

4. Upload Sample Raw Data
Upload a CSV file or other raw data for processing.
aws s3 cp s3-samples/sample_data.csv s3://data-pipeline-raw-us-west-1/

5. Set Up AWS Glue
A. Create a Glue Database
In the AWS Console:
Go to AWS Glue → Databases.
Create a database called data_pipeline_db.

B. Create a Glue Crawler
Source: data-pipeline-raw-us-west-1
Target database: data_pipeline_db
Run crawler to generate schema tables.

6. Create and Run Glue Job
Upload the ETL script located in glue-scripts/transform_data.py:
Go to AWS Glue → Jobs.
Create a new job with:
IAM Role: Role with S3 and Glue permissions.
Script Location: glue-scripts/transform_data.py
Output: s3://data-pipeline-processed-us-west-1/
Run the job and verify successful completion.

7. Query Processed Data with Athena
Go to Amazon Athena in the AWS Console.
Set the query result location to a dedicated bucket:
s3://data-pipeline-athena-results-us-west-1/
Run SQL queries against the processed data.
Example:
SELECT * FROM processed_table LIMIT 10;

8. Monitor Pipeline
Use CloudWatch Logs to view Glue job run details.
Set up CloudWatch Alarms for failures or unexpected behaviors.

9. Clean Up Resources
To avoid AWS charges, delete all resources when finished:
aws s3 rm s3://data-pipeline-raw-us-west-1 --recursive
aws s3 rm s3://data-pipeline-processed-us-west-1 --recursive
aws s3 rb s3://data-pipeline-raw-us-west-1 --force
aws s3 rb s3://data-pipeline-processed-us-west-1 --force

Security Considerations
IAM Least Privilege – Only grant Glue and Athena access to the necessary S3 buckets.
S3 Bucket Policies – Restrict public access to all buckets.
Encryption – Enable S3 bucket encryption (SSE-S3 or SSE-KMS).
CloudTrail – Track API calls for auditing and compliance.

Future Enhancements
Automate ETL job triggering using AWS Lambda and S3 event notifications.
Add Amazon Redshift as a data warehouse for large-scale analytics.
Build visual dashboards using Amazon QuickSight.
Enable cross-region replication for disaster recovery.

License
This project is licensed under the MIT License.
