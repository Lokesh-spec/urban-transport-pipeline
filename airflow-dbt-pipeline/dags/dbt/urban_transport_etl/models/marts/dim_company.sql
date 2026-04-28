{{ config(materialized='table') }}

WITH distinct_companies AS (
    SELECT DISTINCT company
    FROM {{ ref('stg_taxi_trips') }}
    WHERE company IS NOT NULL AND company != ''
)

SELECT
    -- Using FARM_FINGERPRINT but cast to ABS string or just ABS int to avoid negative keys
    company AS company_name,
    ABS(FARM_FINGERPRINT(company)) AS company_key
FROM distinct_companies
