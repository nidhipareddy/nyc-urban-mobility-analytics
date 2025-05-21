CREATE DATABASE IF NOT EXISTS Taxi_data;
USE Taxi_data;

DROP TABLE IF EXISTS fact_ride;   
DROP TABLE IF EXISTS payment_type_dim;   
DROP TABLE IF EXISTS location_dim;         
DROP TABLE IF EXISTS census;
DROP TABLE IF EXISTS merged_taxi;
DROP TABLE IF EXISTS time_dim;
DROP TABLE IF EXISTS taxi_dim;
DROP TABLE IF EXISTS hire_vehicles_dim;
DROP TABLE IF EXISTS staging_hire_vehicles;

 CREATE TABLE IF NOT EXISTS taxi_dim (
                taxi_id INT AUTO_INCREMENT PRIMARY KEY,
                vendor_id INT NOT NULL,
                taxi_type VARCHAR(10)
            );

CREATE TABLE IF NOT EXISTS hire_vehicles_dim (
                hire_vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
                dispatching_base_num VARCHAR(50),
                hvfhs_license_num VARCHAR(50),
                wav_flag TINYINT
            );

CREATE TABLE IF NOT EXISTS time_dim (
                time_id INT AUTO_INCREMENT PRIMARY KEY,
                pickup_datetime DATETIME,
                dropoff_datetime DATETIME,
                pickup_day INT,
                pickup_hour INT,
                pickup_minute INT,
                dropoff_day INT,
                dropoff_hour INT,
                dropoff_minute INT
            );

CREATE TABLE IF NOT EXISTS census (
                boroughID INT PRIMARY KEY,
                borough_name VARCHAR(50) NOT NULL,
                pop_total INT,
                pop_under18 INT,
                pop_under65 INT,
                pop_65plus INT,
                pop_density DECIMAL(10, 2),
                hh_total INT,
                hu_total INT,
                land_acres DECIMAL(10, 2)
            );

INSERT INTO census (
    boroughID, 
    borough_name, 
    pop_total, 
    pop_under18, 
    pop_under65, 
    pop_65plus, 
    pop_density, 
    hh_total, 
    hu_total, 
    land_acres
) VALUES
(1, 'Manhattan', 1694251, 232511, 1178557, 283183, 116.8, 817782, 913926, 14500),
(2, 'Bronx', 1472654, 349579, 929705, 193370, 54.6, 522450, 547030, 26990),
(3, 'Brooklyn', 2736074, 595703, 1767759, 372612, 61.6, 1009804, 1077654, 44401),
(4, 'Queens', 2405464, 455995, 1573572, 375897, 34.6, 847210, 896333, 69583),
(5, 'Staten Island', 495747, 106354, 304231, 85162, 13.5, 173202, 183692, 36814);

CREATE TABLE IF NOT EXISTS location_dim (
                location_id INT AUTO_INCREMENT PRIMARY KEY,
                boroughID INT NOT NULL,
                zone VARCHAR(100) NOT NULL,
                service_zone VARCHAR(100),
                FOREIGN KEY (boroughID) REFERENCES census(boroughID)
            );

CREATE TABLE IF NOT EXISTS payment_type_dim (
	payment_type_id TINYINT,
    payment_type_category VARCHAR(20),
    PRIMARY KEY (payment_type_id)
);

CREATE TABLE IF NOT EXISTS fact_ride (
                ride_id INT AUTO_INCREMENT PRIMARY KEY,
                pickup_datetime DATETIME NOT NULL,
                dropoff_datetime DATETIME NOT NULL,
                passenger_count INT,
                trip_distance DECIMAL(10, 2),
                fare_amount DECIMAL(10, 2),
                total_amount DECIMAL(10, 2),
                congestion_surcharge DECIMAL(10, 2),
                PULocationID INT NOT NULL,
                DOLocationID INT NOT NULL,
                dispatching_base_num VARCHAR(50),
                hvfhs_license_num VARCHAR(50),
                taxi_id INT,
                hire_vehicle_id INT,
                time_id INT NOT NULL,
                payment_type_id TINYINT,
                FOREIGN KEY (PULocationID) REFERENCES location_dim(location_id),
                FOREIGN KEY (DOLocationID) REFERENCES location_dim(location_id),
                FOREIGN KEY (taxi_id) REFERENCES taxi_dim(taxi_id),
                FOREIGN KEY (hire_vehicle_id) REFERENCES hire_vehicles_dim(hire_vehicle_id),
                FOREIGN KEY (time_id) REFERENCES time_dim(time_id),
				FOREIGN KEY (payment_type_id) REFERENCES payment_type_dim(payment_type_id)
            );

INSERT INTO payment_type_dim (
	payment_type_id,
    payment_type_category
) VALUES
(0, 'Unknown'),
(1, 'Credit card'),
(2, 'Cash'),
(3, 'No charge'),
(4, 'Dispute'),
(5, 'Unknown'),
(6, 'Voided trip');

CREATE TABLE IF NOT EXISTS merged_taxi (
    VendorID INT NOT NULL,
    pickup_datetime DATETIME NOT NULL,
    dropoff_datetime DATETIME NOT NULL,
    PULocationID INT NOT NULL,
    DOLocationID INT NOT NULL,
    passenger_count INT,
    trip_distance FLOAT,
    fare_amount FLOAT,
    total_amount FLOAT,
    payment_type INT,
    congestion_surcharge FLOAT,
    taxi_type VARCHAR(10) -- 1 for yellow taxi, 2 for green taxi
);

CREATE TABLE IF NOT EXISTS staging_hire_vehicles (
    hvfhs_license_num VARCHAR(50),
    dispatching_base_num VARCHAR(50),
    pickup_datetime DATETIME NOT NULL,
    dropoff_datetime DATETIME,
    PULocationID INT,
    DOLocationID INT,
    trip_miles FLOAT,
    trip_time INT,
    base_passenger_fare FLOAT,
    tolls FLOAT,
    bcf FLOAT,
    sales_tax FLOAT,
    congestion_surcharge FLOAT,
    airport_fee FLOAT,
    tips FLOAT,
    driver_pay FLOAT,
    shared_request_flag CHAR(1),
    shared_match_flag CHAR(1),
    wav_request_flag CHAR(1),
    wav_match_flag CHAR(1),
    Type VARCHAR(50) # whether it's a rideshare or hired vehicle
);