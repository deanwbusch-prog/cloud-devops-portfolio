-- 1) Choose a workgroup with the right output location (or set in console)
--    Set Athena query results to your athena-results bucket, for example:
--    s3://<account>-data-pipeline-athena-results-us-west-1/

-- 2) Create a logical DB (if not created by Glue already)
CREATE DATABASE IF NOT EXISTS data_pipeline_analytics;

-- 3) Create an external table pointing at the processed parquet (partitioned by order_date)
CREATE EXTERNAL TABLE IF NOT EXISTS data_pipeline_analytics.processed_data (
  order_id      string,
  customer_id   string,
  product_id    string,
  quantity      int,
  price         double,
  total_price   double
)
PARTITIONED BY (order_date string)
STORED AS PARQUET
LOCATION 's3://<processed-bucket>/processed/';

-- 4) If partitions were newly written, discover them
MSCK REPAIR TABLE data_pipeline_analytics.processed_data;

-- 5) Example analytics query
SELECT
  customer_id,
  SUM(total_price) AS total_spent
FROM data_pipeline_analytics.processed_data
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 10;
