import sys
from awsglue.transforms import ApplyMapping
from awsglue.utils import getResolvedOptions
from pyspark.sql import functions as F
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from awsglue.job import Job

# Args we pass from the job config
args = getResolvedOptions(sys.argv, [
    "JOB_NAME",
    "RAW_DATABASE",           # e.g., data_pipeline_db
    "RAW_TABLE",              # e.g., raw_data (from crawler)
    "PROCESSED_S3_PATH"       # e.g., s3://.../processed/
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

raw_db = args["RAW_DATABASE"]
raw_table = args["RAW_TABLE"]
processed_path = args["PROCESSED_S3_PATH"].rstrip("/")

# 1) Load from Data Catalog as DynamicFrame, then convert to Spark DataFrame
raw_dyf = glueContext.create_dynamic_frame.from_catalog(
    database=raw_db, table_name=raw_table
)
df = raw_dyf.toDF()

# 2) Basic normalization / typing
# Cast columns (if crawler inferred as string)
df = df.withColumn("quantity", F.col("quantity").cast("int"))\
       .withColumn("price", F.col("price").cast("double"))

# Ensure order_date is a date (or string kept for partition)
# We'll keep a yyyy-MM-dd string for partitioning (Athena-friendly)
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

# 5) (Optional) Create/Update Glue Catalog table for processed data
# Convert DF back to DynamicFrame and catalog it
processed_dyf = glueContext.create_dynamic_frame.from_rdd(df.rdd, df.schema)
glueContext.write_dynamic_frame.from_options(
    frame=processed_dyf,
    connection_type="s3",
    connection_options={"path": processed_path},
    format="parquet"
)

job.commit()
