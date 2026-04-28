{{
    config(
        materialized='table'
    )
}}

SELECT
    COALESCE(pickup_dca.community_area_key, 0) AS area_key,
    COALESCE(pickup_dca.community_area_name, 'Unknown/Outside Chicago')
        AS community_name,
    COUNT(f.trip_id) AS total_pickups
FROM {{ ref('fct_trips') }} AS f
LEFT JOIN {{ ref('dim_community_area') }} AS pickup_dca
    ON f.pickup_community_key = pickup_dca.community_area_key
GROUP BY
    area_key,
    community_name
ORDER BY
    total_pickups DESC
