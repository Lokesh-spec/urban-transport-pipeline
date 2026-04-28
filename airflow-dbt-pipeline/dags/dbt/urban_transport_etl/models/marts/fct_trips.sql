{{
  config(
    materialized='incremental',
    unique_key='trip_id',  
    partition_by={
      "field" : "date_only",
      "data_type" : "date",
      "granularity" : "day"
    },
    cluster_by=["pickup_community_key", "dropoff_community_key", "company_key"]
  )
}}

WITH base_trips AS (
    SELECT *
    FROM {{ ref('stg_taxi_trips') }}

    {% if is_incremental() %}
        WHERE date_only >= DATE_SUB((
            SELECT COALESCE(MAX(date_only), DATE('1900-01-01'))
            FROM {{ this }}
        ), INTERVAL 7 DAY)
    {% endif %}
),

-- Pre-join dedup
deduped_trips AS (
    SELECT *
    FROM base_trips
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY trip_id, taxi_id
        ORDER BY ingestion_ts DESC
    ) = 1
),

-- Main join logic
final AS (
    SELECT
        t.trip_id,
        t.taxi_id,

        start_date.date_key AS trip_start_date_key,
        start_time.time_key AS trip_start_hour_key,

        end_date.date_key AS trip_end_date_key,
        end_time.time_key AS trip_end_hour_key,

        payment.payment_key,
        company.company_key,

        pickup_area.community_area_key AS pickup_community_key,
        dropoff_area.community_area_key AS dropoff_community_key,

        t.trip_start_timestamp,
        t.trip_end_timestamp,
        t.pickup_centroid_latitude,
        t.pickup_centroid_longitude,
        t.dropoff_centroid_latitude,
        t.dropoff_centroid_longitude,

        t.fare,
        t.tips,
        t.tolls,
        t.extras,
        t.trip_total,
        t.trip_miles AS trip_distance_miles,
        t.date_only,
        t.ingestion_ts,

        ROUND(t.trip_seconds / 60.0, 2) AS trip_duration_minutes

    FROM deduped_trips t

    LEFT JOIN {{ ref('dim_date') }} AS start_date
        ON CAST(FORMAT_DATE('%Y%m%d', DATE(t.trip_start_timestamp)) AS INT64)
           = start_date.date_key

    LEFT JOIN {{ ref('dim_date') }} AS end_date
        ON CAST(FORMAT_DATE('%Y%m%d', DATE(t.trip_end_timestamp)) AS INT64)
           = end_date.date_key

    LEFT JOIN {{ ref('dim_time') }} AS start_time
        ON EXTRACT(HOUR FROM t.trip_start_timestamp) = start_time.hour

    LEFT JOIN {{ ref('dim_time') }} AS end_time
        ON EXTRACT(HOUR FROM t.trip_end_timestamp) = end_time.hour

    LEFT JOIN {{ ref('dim_payment_type') }} AS payment
        ON t.payment_type = payment.payment_type

    LEFT JOIN {{ ref('dim_company') }} AS company
        ON t.company = company.company_name

    LEFT JOIN {{ ref('dim_community_area') }} AS pickup_area
        ON CAST(t.pickup_community_area AS INT64) = pickup_area.community_area_id

    LEFT JOIN {{ ref('dim_community_area') }} AS dropoff_area
        ON CAST(t.dropoff_community_area AS INT64) = dropoff_area.community_area_id
),

-- Post-join safety dedup (handles join explosions)
final_dedup AS (
    SELECT *
    FROM final
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY trip_id, taxi_id
        ORDER BY ingestion_ts DESC
    ) = 1
)

SELECT * FROM final_dedup