{{ config(materialized='table') }}

WITH date_spine AS (
    -- Generating dates statically saves scanning the massive Staging table
    SELECT date_actual
    FROM
        UNNEST(
            GENERATE_DATE_ARRAY('2010-01-01', '2030-12-31', INTERVAL 1 DAY)
        ) AS date_actual
)

SELECT
    date_actual AS date,
    CAST(FORMAT_DATE('%Y%m%d', date_actual) AS INT64) AS date_key,
    EXTRACT(YEAR FROM date_actual) AS year,
    EXTRACT(MONTH FROM date_actual) AS month,
    EXTRACT(QUARTER FROM date_actual) AS quarter,
    EXTRACT(WEEK FROM date_actual) AS week_number,
    EXTRACT(DAYOFWEEK FROM date_actual) AS week_day,
    EXTRACT(DAYOFYEAR FROM date_actual) AS day_of_year
FROM date_spine
