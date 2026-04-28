{{ config(materialized='table') }}

WITH distinct_payments AS (
    SELECT DISTINCT payment_type
    FROM {{ ref('stg_taxi_trips') }}
    WHERE payment_type IS NOT NULL AND payment_type != ''
)

SELECT
    -- Replaced ROW_NUMBER with FARM_FINGERPRINT. ROW_NUMBER is dangerous in dbt because 
    -- if a new payment type appears, the alphabetical sorting changes, shifting all keys!
    payment_type,
    ABS(FARM_FINGERPRINT(payment_type)) AS payment_key
FROM distinct_payments
