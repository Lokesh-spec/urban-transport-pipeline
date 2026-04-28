{{
    config(
        materialized='table'
    )
}}

SELECT
    COALESCE(dc.company_name, 'Independent/Unknown') AS company_name,
    COUNT(ft.trip_id) AS total_volume,
    ROUND(SUM(ft.trip_total), 2) AS total_revenue,
    ROUND(SUM(ft.fare), 2) AS total_fare_revenue
FROM {{ ref('fct_trips') }} AS ft
LEFT JOIN {{ ref('dim_company') }} AS dc
    ON ft.company_key = dc.company_key
GROUP BY
    1
ORDER BY
    total_revenue DESC
