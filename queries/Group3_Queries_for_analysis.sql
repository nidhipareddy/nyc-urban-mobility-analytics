USE Taxi_data;
SET SESSION net_read_timeout = 600;
SET SESSION net_write_timeout = 600;

#Query-1: Popular routes(Zone wise):
WITH ride_counts AS (
    SELECT 
        PULocationID, 
        DOLocationID, 
        COUNT(*) AS ride_count
    FROM fact_ride
    GROUP BY PULocationID, DOLocationID
),
pickup_zones AS (
    SELECT 
        rc.PULocationID, 
        rc.DOLocationID, 
        rc.ride_count, 
        pl.zone AS pickup_zone
    FROM ride_counts rc
    JOIN location_dim pl ON rc.PULocationID = pl.location_id
),
pickup_and_dropoff_zones AS (
    SELECT 
        pz.PULocationID, 
        pz.pickup_zone, 
        pz.DOLocationID, 
        dl.zone AS dropoff_zone, 
        pz.ride_count
    FROM pickup_zones pz
    JOIN location_dim dl ON pz.DOLocationID = dl.location_id
)
SELECT 
    PULocationID, 
    pickup_zone, 
    DOLocationID, 
    dropoff_zone, 
    ride_count
FROM pickup_and_dropoff_zones
ORDER BY ride_count DESC
LIMIT 10;

#Query-2: Peak Hours (Rush vs Non-Rush):

WITH hourly_ride_counts AS (
    SELECT 
        fr.time_id,
        td.pickup_hour,
        COUNT(*) AS ride_count
    FROM fact_ride fr
    JOIN time_dim td ON fr.time_id = td.time_id
    GROUP BY fr.time_id, td.pickup_hour
),
time_period_classification AS (
    SELECT 
        pickup_hour,
        SUM(ride_count) AS total_ride_count,
        CASE 
            WHEN pickup_hour BETWEEN 7 AND 9 THEN 'Morning Rush'
            WHEN pickup_hour BETWEEN 17 AND 19 THEN 'Evening Rush'
            ELSE 'Non-Rush'
        END AS time_period
    FROM hourly_ride_counts
    GROUP BY pickup_hour, time_period
)
SELECT 
    pickup_hour, 
    total_ride_count AS ride_count, 
    time_period
FROM time_period_classification
ORDER BY ride_count DESC;

#Query-3: Census - Popularity vs Population: Total population in boroughs vs. the rides taken
WITH location_rides AS (
    SELECT 
        PULocationID, 
        COUNT(ride_id) AS ride_count
    FROM fact_ride
    GROUP BY PULocationID
),

borough_rides AS (
    SELECT 
        lr.PULocationID, 
        l.borough_name, 
        l.pop_total, 
        lr.ride_count
    FROM location_rides lr
    JOIN location_dim l ON lr.PULocationID = l.location_id
)

SELECT 
    borough_name, 
    pop_total, 
    SUM(ride_count) AS total_rides
FROM borough_rides
GROUP BY borough_name, pop_total
ORDER BY total_rides DESC;

#Query-4: How many rides are accessible or inaccessible -> Wheelchair accessibility(wav flag):

WITH vehicle_rides AS (
    SELECT 
        hire_vehicle_id, 
        COUNT(*) AS ride_count
    FROM fact_ride
    GROUP BY hire_vehicle_id
),

wav_rides AS (
    SELECT 
        v.hire_vehicle_id, 
        h.wav_flag, 
        v.ride_count
    FROM vehicle_rides v
    JOIN hire_vehicles_dim h ON v.hire_vehicle_id = h.hire_vehicle_id
)

SELECT 
    wav_flag, 
    SUM(ride_count) AS ride_count
FROM wav_rides
GROUP BY wav_flag
ORDER BY ride_count DESC;

#Query-5: All routes with wheelchair accessible rides (wheelchair accessibility- wav flag=1):

-- Aggregate ride counts by hire_vehicle_id, PULocationID, and DOLocationID
WITH vehicle_rides AS (
    SELECT 
        f.hire_vehicle_id, 
        f.PULocationID, 
        f.DOLocationID, 
        COUNT(*) AS ride_count
    FROM fact_ride f
    GROUP BY f.hire_vehicle_id, f.PULocationID, f.DOLocationID
),

-- Join the aggregated data with hire_vehicles_dim to include WAV flag
wav_rides AS (
    SELECT 
        vr.hire_vehicle_id, 
        vr.PULocationID, 
        vr.DOLocationID, 
        vr.ride_count, 
        h.wav_flag
    FROM vehicle_rides vr
    JOIN hire_vehicles_dim h ON vr.hire_vehicle_id = h.hire_vehicle_id
),

-- Add zone names for PULocationID and DOLocationID
zone_routes AS (
    SELECT 
        wr.PULocationID, 
        pl.zone AS pickup_zone, 
        wr.DOLocationID, 
        dl.zone AS dropoff_zone, 
        wr.ride_count, 
        wr.wav_flag
    FROM wav_rides wr
    JOIN location_dim pl ON wr.PULocationID = pl.location_id
    JOIN location_dim dl ON wr.DOLocationID = dl.location_id
),

-- Aggregate rides by route and WAV flag
route_analysis AS (
    SELECT 
        pickup_zone, 
        dropoff_zone, 
        wav_flag, 
        SUM(ride_count) AS total_rides
    FROM zone_routes
    GROUP BY pickup_zone, dropoff_zone, wav_flag
)

-- Filter and display results for accessible rides (wav_flag = 1)
SELECT 
    pickup_zone, 
    dropoff_zone, 
    total_rides AS accessible_rides
FROM route_analysis
WHERE wav_flag = 1
ORDER BY accessible_rides DESC;

#Query-6: Choice of Ride (Taxi vs Rideshare):
-- Aggregate rides by taxi_id and dispatching_base_num
WITH aggregated_rides AS (
    SELECT 
        f.taxi_id,
        f.dispatching_base_num,
        COUNT(*) AS ride_count
    FROM fact_ride f
    GROUP BY f.taxi_id, f.dispatching_base_num
),

-- Classify rides as Taxi or Rideshare with appropriate identifiers
ride_classification AS (
    SELECT 
        CASE 
            WHEN ar.taxi_id IS NOT NULL THEN ar.taxi_id
            ELSE ar.dispatching_base_num
        END AS identifier,
        CASE 
            WHEN ar.taxi_id IS NOT NULL THEN 'Taxi'
            ELSE 'Rideshare'
        END AS ride_type,
        ar.ride_count
    FROM aggregated_rides ar
)

SELECT 
    identifier, 
    ride_type, 
    SUM(ride_count) AS ride_count
FROM ride_classification
GROUP BY identifier, ride_type
ORDER BY ride_count DESC;

