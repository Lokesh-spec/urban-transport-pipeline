{{ config(materialized='table') }}

WITH community_areas AS (
    SELECT DISTINCT CAST(pickup_community_area AS INT64) AS community_area
    FROM {{ ref('stg_taxi_trips') }}

    UNION DISTINCT

    SELECT DISTINCT CAST(dropoff_community_area AS INT64) AS community_area
    FROM {{ ref('stg_taxi_trips') }}
),

-- Deduplicate mapping (CRITICAL FIX)
community_mapping AS (
    SELECT
        CAST(area_number AS INT64) AS area_id,
        community AS community_area_name
    FROM {{ ref('community_areas_mapping') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY CAST(area_number AS INT64)
        ORDER BY community
    ) = 1
)

SELECT
    cm.community_area_name,
    ca.community_area AS community_area_key,
    ca.community_area AS community_area_id,
    CAST(NULL AS STRING) AS city_region
FROM community_areas AS ca
LEFT JOIN community_mapping AS cm
    ON ca.community_area = cm.area_id
WHERE ca.community_area IS NOT NULL

