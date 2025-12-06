import sys
import logging

from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import functions as F

# Set up basic logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def main():
    # Arguments passed from the Glue Job configuration
    args = getResolvedOptions(
        sys.argv,
        [
            "JOB_NAME",
            "RAW_DATABASE",      # e.g. data_pipeline_db
            "RAW_TABLE",         # e.g. raw_data (from crawler)
            "PROCESSED_S3_PATH", # e.g. s3://.../processed/
        ],
    )

    sc = SparkContext()
    glue_context = GlueContext(sc)
    spark = glue_context.spark_session

    job = Job(glue_context)
    job.init(args["JOB_NAME"], args)

    raw_db = args["RAW_DATABASE"]
    raw_table = args["RAW_TABLE"]
    processed_path = args["PROCESSED_S3_PATH"].rstrip("/")

    logger.info("Starting Glue job")
    logger.info("RAW_DATABASE=%s RAW_TABLE=%s PROCESSED_S3_PATH=%s", raw_db, raw_table, processed_path)

    # 1) Load from Data Catalog as DynamicFrame, then convert to Spark DataFrame
    raw_dyf = glue_context.create_dynamic_frame.from_catalog(
        database=raw_db,
        table_name=raw_table,
    )
    df = raw_dyf.toDF()

    logger.info("Loaded %d rows from %s.%s", df.count(), raw_db, raw_table)

    # 2) Basic normalization / typing
    # Cast columns (if crawler inferred as string)
    df = (
        df.withColumn("quantity", F.col("quantity").cast("int"))
        .withColumn("price", F.col("price").cast("double"))
    )

    # Ensure order_date is a date, then keep yyyy-MM-dd string for partitioning (Athena-friendly)
    df = df.withColumn("order_date", F.to_date(F.col("order_date")).cast("string"))

    # 3) Feature engineering: total_price = quantity * price
    df = df.withColumn("total_price", F.col("quantity") * F.col("price"))

    # 4) Write to parquet, partitioned by order_date
    # Overwrite partitions for idempotency (lab-friendly)
    (
        df.repartition("order_date")
        .write.mode("overwrite")
        .format("parquet")
        .partitionBy("order_date")
        .save(processed_path)
    )

    logger.info("Wrote processed data to %s", processed_path)

    # 5) (Optional) Create/Update Glue Catalog table for processed data (kept minimal)
    # If you want to catalog the processed data, you can enable this block later:
    # processed_dyf = glue_context.create_dynamic_frame.from_rdd(df.rdd, df.schema)
    # glue_context.write_dynamic_frame.from_options(
    #     frame=processed_dyf,
    #     connection_type="s3",
    #     connection_options={"path": processed_path},
    #     format="parquet",
    # )

    job.commit()
    logger.info("Job completed successfully")


if __name__ == "__main__":
    main()
