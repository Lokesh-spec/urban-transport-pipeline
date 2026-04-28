{{
    config(
        materialized='table'
    )
}}

SELECT
    COALESCE(dpt.payment_type, 'Unknown') AS payment_type,
    COUNT(ft.trip_id) AS trip_count,
    ROUND((COUNT(ft.trip_id) / SUM(COUNT(ft.trip_id)) OVER ()) * 100.0, 2)
        AS percentage_share
FROM {{ ref('fct_trips') }} AS ft
LEFT JOIN {{ ref('dim_payment_type') }} AS dpt
    ON ft.payment_key = dpt.payment_key
GROUP BY
    payment_type
ORDER BY
    percentage_share DESC
