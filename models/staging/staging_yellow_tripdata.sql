{{ config({"materialized": "table"}) }}

SELECT * FROM 'data/raw/yellow_tripdata_2026-07.parquet'
