from aws_cdk import (
    Stack,
    aws_s3 as s3,
    aws_iam as iam,
    aws_glue as glue,
)
from constructs import Construct


class DataPipelineStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, project_name: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        account = self.account
        region = self.region

        raw_bucket_name = f"{account}-{project_name}-raw-{region}"
        processed_bucket_name = f"{account}-{project_name}-processed-{region}"
        athena_bucket_name = f"{account}-{project_name}-athena-results-{region}"

        # Import existing S3 buckets by name
        self.raw_bucket = s3.Bucket.from_bucket_name(
            self,
            "RawBucket",
            bucket_name=raw_bucket_name,
        )

        self.processed_bucket = s3.Bucket.from_bucket_name(
            self,
            "ProcessedBucket",
            bucket_name=processed_bucket_name,
        )

        self.athena_results_bucket = s3.Bucket.from_bucket_name(
            self,
            "AthenaResultsBucket",
            bucket_name=athena_bucket_name,
        )

        # Glue service role for ETL jobs and crawler
        self.glue_role = iam.Role(
            self,
            "GlueServiceRole",
            assumed_by=iam.ServicePrincipal("glue.amazonaws.com"),
            role_name=f"{project_name}-glue-role-{region}",
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name("service-role/AWSGlueServiceRole"),
            ],
        )

        # Inline policy for S3 access (raw, processed, athena-results)
        self.glue_role.add_to_policy(
            iam.PolicyStatement(
                sid="GlueS3Access",
                actions=[
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket",
                ],
                resources=[
                    f"arn:aws:s3:::{raw_bucket_name}",
                    f"arn:aws:s3:::{raw_bucket_name}/*",
                    f"arn:aws:s3:::{processed_bucket_name}",
                    f"arn:aws:s3:::{processed_bucket_name}/*",
                    f"arn:aws:s3:::{athena_bucket_name}",
                    f"arn:aws:s3:::{athena_bucket_name}/*",
                ],
            )
        )

        # Glue database
        self.glue_database = glue.CfnDatabase(
            self,
            "DataPipelineDatabase",
            catalog_id=account,
            database_input=glue.CfnDatabase.DatabaseInputProperty(
                name="data_pipeline_db",
                description="Glue database for data pipeline raw data",
            ),
        )

        # Glue crawler for raw CSV
        self.glue_crawler = glue.CfnCrawler(
            self,
            "RawCsvCrawler",
            name="raw-csv-crawler",
            role=self.glue_role.role_arn,
            database_name=self.glue_database.database_input.name,
            targets=glue.CfnCrawler.TargetsProperty(
                s3_targets=[
                    glue.CfnCrawler.S3TargetProperty(
                        path=f"s3://{raw_bucket_name}/raw-data/",
                    )
                ]
            ),
            schema_change_policy=glue.CfnCrawler.SchemaChangePolicyProperty(
                delete_behavior="DEPRECATE_IN_DATABASE",
                update_behavior="UPDATE_IN_DATABASE",
            ),
        )

        # Glue ETL job: raw to processed parquet
        # Make sure the script has been uploaded to:
        #   s3://<account>-data-pipeline-processed-us-east-2/scripts/transform_data.py
        script_location = f"s3://{processed_bucket_name}/scripts/transform_data.py"

        # IMPORTANT: set this to your actual raw table name from the crawler
        raw_table_name = f"{account}_data_pipeline_raw_us_east_2"

        self.glue_job = glue.CfnJob(
            self,
            "RawToProcessedParquetJob",
            name="raw-to-processed-parquet",
            role=self.glue_role.role_arn,
            command=glue.CfnJob.JobCommandProperty(
                name="glueetl",
                python_version="3",
                script_location=script_location,
            ),
            glue_version="4.0",
            default_arguments={
                "--RAW_DATABASE": "data_pipeline_db",
                "--RAW_TABLE": raw_table_name,
                "--PROCESSED_S3_PATH": f"s3://{processed_bucket_name}/processed/",
                "--job-language": "python",
                "--enable-continuous-cloudwatch-log": "true",
                "--enable-metrics": "true",
            },
            max_retries=0,
            number_of_workers=2,
            worker_type="G.1X",
        )

        # Ensure job is created after database and crawler definition
        self.glue_job.add_dependency(self.glue_database)
        self.glue_job.add_dependency(self.glue_crawler)
