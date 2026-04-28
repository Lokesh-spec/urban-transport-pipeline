-- Ensure we have roughly the expected volume for 2020
-- (Adjust 1000000 to your actual expected count)
SELECT COUNT(*) 
FROM {{ ref('stg_trips') }} 
WHERE trip_year = 2020 
HAVING COUNT(*) < 4000000 
