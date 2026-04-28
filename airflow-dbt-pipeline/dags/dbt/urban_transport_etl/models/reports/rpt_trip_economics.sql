{{
    config(
        materialized='table'
    )
}}

-- ==============================================================================
-- MODEL: rpt_trip_economics
-- DESCRIPTION: Aggregates trips into standard distance categories to analyze 
-- pricing patterns, calculating the average fare and fare-per-mile efficiency.
-- ==============================================================================

WITH base_economics AS (
    SELECT
        -- Standardize numeric distance into analytical categorical buckets
        trip_duration_minutes,
        trip_distance_miles,
        fare,
        CASE
            WHEN trip_distance_miles < 2 THEN '1. Short (0-2 Miles)'
            WHEN
                trip_distance_miles >= 2 AND trip_distance_miles < 5
                THEN '2. Medium (2-5 Miles)'
            WHEN
                trip_distance_miles >= 5 AND trip_distance_miles < 10
                THEN '3. Long (5-10 Miles)'
            WHEN trip_distance_miles >= 10 THEN '4. Very Long (10+ Miles)'
            ELSE 'Unknown Distance'
        END AS trip_distance_category,
        fare / NULLIF(trip_distance_miles, 0) AS fare_per_mile
    FROM {{ ref('fct_trips') }}
    WHERE
        trip_distance_miles IS NOT NULL
        AND trip_duration_minutes IS NOT NULL
)

SELECT
    trip_distance_category,
    COUNT(*) AS total_trips,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    ROUND(AVG(trip_distance_miles), 2) AS avg_distance_miles,
    ROUND(AVG(fare), 2) AS avg_fare,
    ROUND(AVG(fare_per_mile), 2) AS avg_fare_per_mile
FROM base_economics
GROUP BY
    1
ORDER BY
    1
