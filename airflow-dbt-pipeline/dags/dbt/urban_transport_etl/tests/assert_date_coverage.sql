-- Ensure we have data for all expected months in 2020
SELECT COUNT(DISTINCT date_only) as days_present
FROM {{ ref('stg_trips') }}
WHERE trip_year = 2020
HAVING days_present < 366 
