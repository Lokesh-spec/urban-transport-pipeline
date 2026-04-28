{{
    config(
        materialized='table'
    )
}}

SELECT
    d.date AS trip_date,
    d.week_day AS peak_day,
    t.hour AS peak_hour,
    t.day_part,
    COUNT(f.trip_id) AS total_trip_count
FROM {{ ref('fct_trips') }} AS f
LEFT JOIN {{ ref('dim_date') }} AS d
    ON f.trip_start_date_key = d.date_key
LEFT JOIN {{ ref('dim_time') }} AS t
    ON f.trip_start_hour_key = t.time_key
GROUP BY
    1, 2, 3, 4
ORDER BY
    total_trip_count DESC
