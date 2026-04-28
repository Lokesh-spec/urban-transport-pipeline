{{
    config(
        materialized='table'
    )
}}

SELECT
    COALESCE(pickup_dca.community_area_name, 'Unknown Pickup') AS pickup_area,
    COALESCE(dropoff_dca.community_area_name, 'Unknown Dropoff')
        AS dropoff_area,
    COUNT(f.trip_id) AS trip_flow_volume
FROM {{ ref('fct_trips') }} AS f
LEFT JOIN {{ ref('dim_community_area') }} AS pickup_dca
    ON f.pickup_community_key = pickup_dca.community_area_key
LEFT JOIN {{ ref('dim_community_area') }} AS dropoff_dca
    ON f.dropoff_community_key = dropoff_dca.community_area_key
GROUP BY
    1, 2
ORDER BY
    trip_flow_volume DESC
