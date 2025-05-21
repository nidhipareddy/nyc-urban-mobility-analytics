USE Taxi_data;

INSERT INTO taxi_dim (vendor_id, taxi_type)
SELECT DISTINCT VendorID, taxi_type
FROM merged_taxi;

INSERT INTO hire_vehicles_dim (dispatching_base_num, hvfhs_license_num, wav_flag)
SELECT DISTINCT
    dispatching_base_num,
    hvfhs_license_num,
    CASE 
        WHEN wav_request_flag = 'Y' THEN 1
        ELSE 0
    END AS wav_flag
FROM staging_hire_vehicles;

INSERT INTO time_dim (pickup_datetime, dropoff_datetime, pickup_day, pickup_hour, pickup_minute, dropoff_day, dropoff_hour, dropoff_minute)
SELECT DISTINCT
    pickup_datetime,
    dropoff_datetime,
    DAY(pickup_datetime) AS pickup_day,
    HOUR(pickup_datetime) AS pickup_hour,
    MINUTE(pickup_datetime) AS pickup_minute,
    DAY(dropoff_datetime) AS dropoff_day,
    HOUR(dropoff_datetime) AS dropoff_hour,
    MINUTE(dropoff_datetime) AS dropoff_minute
FROM staging_hire_vehicles
UNION
SELECT DISTINCT
    pickup_datetime,
    dropoff_datetime,
    DAY(pickup_datetime) AS pickup_day,
    HOUR(pickup_datetime) AS pickup_hour,
    MINUTE(pickup_datetime) AS pickup_minute,
    DAY(dropoff_datetime) AS dropoff_day,
    HOUR(dropoff_datetime) AS dropoff_hour,
    MINUTE(dropoff_datetime) AS dropoff_minute
FROM merged_taxi;



INSERT INTO fact_ride (
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    fare_amount,
    total_amount,
    congestion_surcharge,
    PULocationID,
    DOLocationID,
    dispatching_base_num,
    hvfhs_license_num,
    taxi_id,
    hire_vehicle_id,
    time_id,
    payment_type_id
)
SELECT
    shv.pickup_datetime,
    shv.dropoff_datetime,
    NULL AS passenger_count, -- Not applicable for hire vehicles
    shv.trip_miles AS trip_distance,
    shv.base_passenger_fare AS fare_amount,
    shv.base_passenger_fare + shv.tolls + shv.bcf + shv.sales_tax + shv.congestion_surcharge + shv.airport_fee + shv.tips AS total_amount,
    shv.congestion_surcharge,
    loc_pickup.location_id AS PULocationID,
    loc_dropoff.location_id AS DOLocationID,
    shv.dispatching_base_num,
    shv.hvfhs_license_num,
    NULL AS taxi_id, -- Not applicable for hire vehicles
    hv.hire_vehicle_id,
    td.time_id,
    NULL AS payment_type -- Not applicable for hire vehicles
FROM staging_hire_vehicles shv
JOIN location_dim loc_pickup ON shv.PULocationID = loc_pickup.location_id
JOIN location_dim loc_dropoff ON shv.DOLocationID = loc_dropoff.location_id
JOIN hire_vehicles_dim hv ON shv.dispatching_base_num = hv.dispatching_base_num
JOIN time_dim td ON shv.pickup_datetime = td.pickup_datetime;

ALTER TABLE fact_ride MODIFY hire_vehicle_id INT NULL;

INSERT INTO fact_ride (
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    fare_amount,
    total_amount,
    congestion_surcharge,
    PULocationID,
    DOLocationID,
    dispatching_base_num,
    hvfhs_license_num,
    taxi_id,
    hire_vehicle_id,
    time_id,
    payment_type_id
)
SELECT
    mt.pickup_datetime,
    mt.dropoff_datetime,
    mt.passenger_count,
    mt.trip_distance,
    mt.fare_amount,
    mt.total_amount,
    mt.congestion_surcharge,
    loc_pickup.location_id AS PULocationID,
    loc_dropoff.location_id AS DOLocationID,
    NULL AS dispatching_base_num,
    NULL AS hvfhs_license_num,
    t.taxi_id,
    NULL AS hire_vehicle_id, -- Placeholder for yellow/green taxi
    td.time_id,
    mt.payment_type
FROM merged_taxi mt
JOIN location_dim loc_pickup ON mt.PULocationID = loc_pickup.location_id
JOIN location_dim loc_dropoff ON mt.DOLocationID = loc_dropoff.location_id
JOIN taxi_dim t ON mt.VendorID = t.vendor_id
JOIN time_dim td ON mt.pickup_datetime = td.pickup_datetime;

DROP TABLE IF EXISTS staging_hire_vehicles;
DROP TABLE IF EXISTS merged_taxi;

ALTER TABLE location_dim
ADD COLUMN borough_name VARCHAR(50),
ADD COLUMN pop_total INT,
ADD COLUMN pop_under18 INT,
ADD COLUMN pop_under65 INT,
ADD COLUMN pop_65plus INT,
ADD COLUMN pop_density DECIMAL(10, 2),
ADD COLUMN hh_total INT,
ADD COLUMN hu_total INT,
ADD COLUMN land_acres DECIMAL(10, 2);

UPDATE location_dim ld
JOIN census c ON ld.boroughID = c.boroughID
SET 
    ld.borough_name = c.borough_name,
    ld.pop_total = c.pop_total,
    ld.pop_under18 = c.pop_under18,
    ld.pop_under65 = c.pop_under65,
    ld.pop_65plus = c.pop_65plus,
    ld.pop_density = c.pop_density,
    ld.hh_total = c.hh_total,
    ld.hu_total = c.hu_total,
    ld.land_acres = c.land_acres;


ALTER TABLE location_dim 
DROP FOREIGN KEY location_dim_ibfk_1;

ALTER TABLE location_dim 
DROP COLUMN boroughID;

DROP TABLE IF EXISTS census;