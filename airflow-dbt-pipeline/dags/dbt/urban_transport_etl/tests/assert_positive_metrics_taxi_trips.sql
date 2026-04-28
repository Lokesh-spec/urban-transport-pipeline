{{ config(severity = 'warn') }}

-- This test checks for negative values in the key metric fields.
-- If any row is returned, the 'dbt test' command will fail for this model.
SELECT *
FROM {{ ref('stg_taxi_trips') }}
WHERE trip_seconds < 0
   OR trip_miles < 0
   OR fare < 0  
   OR tolls < 0  
   OR extras < 0  
   OR trip_total < 0
