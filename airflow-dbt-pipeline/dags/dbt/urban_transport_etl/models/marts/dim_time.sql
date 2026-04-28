{{ config(materialized='table') }}

WITH hours AS (
    -- Generate the 24 hours of the day statically (0 to 23)
    SELECT hour_value
    FROM UNNEST(GENERATE_ARRAY(0, 23)) AS hour_value
)

SELECT
    hour_value AS time_key,
    hour_value AS hour,
    FORMAT_TIME('%p', TIME(hour_value, 0, 0)) AS am_pm,
    CASE
        WHEN hour_value >= 5 AND hour_value < 12 THEN 'MORNING'
        WHEN hour_value >= 12 AND hour_value < 17 THEN 'AFTERNOON'
        WHEN hour_value >= 17 AND hour_value < 21 THEN 'EVENING'
        ELSE 'NIGHT'
    END AS day_part
FROM hours
