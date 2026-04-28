{{
  config(
    materialized='incremental',
    unique_key='trip_id',
    alias='stg_taxi_trips',
    partition_by={
      "field": "date_only",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["company"],
    incremental_strategy='merge'
  )
}}

-- ==============================================================================
-- MODEL: stg_taxi_trips
-- DESCRIPTION: Core staging layer with partition filter for ALL runs
-- ==============================================================================

WITH enriched_taxi_data AS (

    SELECT
        -- Location fields
        pickup_centroid_latitude,
        pickup_centroid_longitude,
        pickup_centroid_location,
        dropoff_centroid_latitude,
        dropoff_centroid_longitude,
        dropoff_centroid_location,

        -- Metadata
        ingestion_ts,

        -- Trip identifiers (cleaned)
        TRIM(trip_id) AS trip_id,
        TRIM(taxi_id) AS taxi_id,

        -- Timestamps
        trip_start_timestamp,
        trip_end_timestamp,
        trip_seconds,
        trip_miles,

        -- Census tracts
        pickup_census_tract,
        dropoff_census_tract,

        -- Community areas
        pickup_community_area,
        dropoff_community_area,

        -- Financial fields
        fare,
        tips,
        tolls,
        extras,
        trip_total,

        -- Categorical (normalized)
        TRIM(UPPER(payment_type)) AS payment_type,
        TRIM(UPPER(company)) AS company,

        -- Partition field
        date_only

    FROM {{ source('raw_urban_mobility_dev', 'taxi_trips_raw') }}

    -- ALWAYS filter on date_only (required by source table)
    WHERE date_only >= '2020-01-01'

    {% if is_incremental() %}
        -- Additional filter for incremental runs (7-day lookback)
        AND date_only >= DATE_SUB(
            (SELECT COALESCE(MAX(date_only), DATE('1900-01-01')) FROM {{ this }}),
            INTERVAL 7 DAY
        )
    {% endif %}

)

-- Deduplicate: keep most recent record per trip_id
SELECT * EXCEPT (rn)
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY trip_id
            ORDER BY ingestion_ts DESC, trip_start_timestamp DESC
        ) AS rn
    FROM enriched_taxi_data
)
WHERE rn = 1
