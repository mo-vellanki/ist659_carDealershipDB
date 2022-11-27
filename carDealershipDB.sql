USE master
-- DOWN

--DROP the FK constraints
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_cars_car_type')
    ALTER TABLE cars DROP CONSTRAINT FK_cars_car_type
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_cars_info_car_id')
    ALTER TABLE cars_information DROP CONSTRAINT FK_cars_info_car_id
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_bids_bid_car_id')
    ALTER TABLE bids DROP CONSTRAINT FK_bids_bid_car_id
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_bids_bid_user_id')
    ALTER TABLE bids DROP CONSTRAINT FK_bids_bid_user_id
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_users_score_provider_id')
    ALTER TABLE users_score_lookup DROP CONSTRAINT FK_users_score_provider_id
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_users_score_user_id')
    ALTER TABLE users_score_lookup DROP CONSTRAINT FK_users_score_user_id
PRINT('Dropped existing constraints')

-- Drop the tables if they already exist
GO
DROP TABLE IF EXISTS cartypes_lookup
GO
DROP TABLE IF EXISTS car_conditions_lookup
GO
DROP TABLE IF EXISTS car_transmissions_lookup
GO
DROP TABLE IF EXISTS cars
GO
DROP TABLE IF EXISTS cars_information
GO
DROP TABLE IF EXISTS users
GO
DROP TABLE IF EXISTS bid_status_lookup
GO
DROP TABLE IF EXISTS bids
GO
DROP TABLE IF EXISTS score_provider_lookup
GO
DROP TABLE IF EXISTS users_score_lookup
GO
DROP TABLE IF EXISTS users_preference
GO
DROP TABLE IF EXISTS car_ratings
PRINT('Dropped existing tables')

-- Drop the database if it already exists
GO
IF EXISTS (SELECT name FROM sys.databases WHERE name='carDealership')
    ALTER database carDealership set single_user with rollback IMMEDIATE
GO
DROP database if EXISTS carDealership;
PRINT('Dropped existing database')

--UP
GO -- execute script to create the new database
IF NOT EXISTS (
    SELECT [name]
        FROM sys.databases
        WHERE [name] = N'carDealership'
)
CREATE DATABASE carDealership
PRINT('Database created')


PRINT('Creating Tables.....')
GO
USE carDealership;

-- Create the users table that contains information about users of the dealership
CREATE TABLE users(
     [user_id] TINYINT NOT NULL IDENTITY(1,1)
    ,[user_email] NVARCHAR(75) NOT NULL
    ,[user_firstname] NVARCHAR(20) NOT NULL
    ,[user_lastname] NVARCHAR(30) NOT NULL
    ,[user_address_street] NVARCHAR(50) NOT NULL
    ,[user_address_city] NVARCHAR(20) NOT NULL
    ,[user_address_state] CHAR(2) NOT NULL
    ,[user_phonenumber_areacode] SMALLINT NOT NULL -- Takes 6bytes to store a split phone number rather than 8bytes for storing it as a single number
    ,[user_phonenumber_telephone] INT NOT NULL
    ,[user_credit_score] SMALLINT NOT NULL
    ,CONSTRAINT [PK_users_user_id] PRIMARY KEY (user_id)
    ,CONSTRAINT [UC_users_user_email] UNIQUE (user_email)
    ,CONSTRAINT [CC_user_credit_score_range] CHECK (user_credit_score >=300 AND user_credit_score<=850)
)



GO
-- Create the cartype_lookup table used in cars table
CREATE TABLE cartypes_lookup ( -- Wagon, Sedan, SUV, Hatchback
    [cartype_type] NVARCHAR(10) NOT NULL
    ,CONSTRAINT [PK_cartypes_lookup_type] PRIMARY KEY (cartype_type)
)

GO
-- Create the car_conditions_lookup table used in cars table
CREATE TABLE car_conditions_lookup (
    [car_conditions_value] TINYINT NOT NULL IDENTITY(1,1) -- 1- Bad, 2 - Good, 3 - average, 4 -good, 5 - v good
    ,[car_conditions_condition] NVARCHAR(10) NOT NULL
    ,CONSTRAINT [PK_car_conditions_lookup_value] PRIMARY KEY (car_conditions_value)
    ,CONSTRAINT [CC_car_conditions_car_condition_value] CHECK (car_conditions_value >=1 AND car_conditions_value <=5)
)

GO
-- Create the car_transmissions_lookup table used in cars table
CREATE TABLE car_transmissions_lookup (
    [car_transmission_type] CHAR(1) NOT NULL
    ,CONSTRAINT [PK_car_transmissions_lookup_type] PRIMARY KEY (car_transmission_type)
)

-- Create the cars table that contains information about cars available at the dealership
GO
CREATE TABLE cars(
     [car_id] TINYINT NOT NULL IDENTITY(100,1)
    ,[car_name] NVARCHAR(50) NOT NULL
    ,[car_type] NVARCHAR(10) NOT NULL
    ,[car_available] BIT NOT NULL CONSTRAINT DV_cars_car_available DEFAULT 1 -- 0=False, 1=True if car is available or not
    ,[car_asking_price] SMALLMONEY NOT NULL -- Assuming we're only dealing cars that cost <214,748
    ,[car_seller_user_id] TINYINT NOT NULL
    ,[car_buyer_user_id] TINYINT NULL
    ,[car_amount_sold] SMALLMONEY NULL -- Assuming we're only dealing cars that cost <214,748
    ,CONSTRAINT [PK_cars_car_id] PRIMARY KEY (car_id)
    ,CONSTRAINT [FK_cars_car_type] FOREIGN KEY (car_type) REFERENCES cartypes_lookup(cartype_type)
    ,CONSTRAINT [FK_cars_car_seller_user_id] FOREIGN KEY (car_seller_user_id) REFERENCES users(user_id)
    ,CONSTRAINT [FK_cars_car_buyer_user_id] FOREIGN KEY (car_buyer_user_id) REFERENCES users(user_id)
    ,CONSTRAINT [CC_cars_seller_isnot_buyer] CHECK (car_seller_user_id != car_buyer_user_id)
-- Create a function to implement this check CONSTRAINT [CC_amount_sold_null_for_avail] CHECK (car_amount_sold is not NULL AND car_available = 0 AND car_buyer_user_id is NULL)
)

-- Create the cars_information table that contains detailed information about cars available at the dealership
GO
CREATE TABLE cars_information(
     [cars_info_car_id] TINYINT NOT NULL
    ,[cars_info_car_description] NVARCHAR(500)
    ,[cars_info_car_transmission] CHAR(1) -- A,M Automatic, Manual
    ,[cars_info_car_colour] NVARCHAR(15) NOT NULL
    ,[cars_info_car_yearOfManf] SMALLINT NOT NULL
    ,[cars_info_car_fueltype] CHAR(3) NOT NULL -- GAS,EL,HY
    ,[cars_info_car_mileage_000] SMALLINT NOT NULL
    ,[cars_info_car_noof_prev_owners] TINYINT NOT NULL
    ,[cars_info_car_condition] TINYINT NOT NULL
    ,CONSTRAINT [PK_cars_info_car_id] PRIMARY KEY (cars_info_car_id)
    ,CONSTRAINT [FK_cars_info_car_id] FOREIGN KEY (cars_info_car_id) REFERENCES cars(car_id)
    ,CONSTRAINT [FK_cars_car_condition] FOREIGN KEY (cars_info_car_condition) REFERENCES car_conditions_lookup(car_conditions_value)
    ,CONSTRAINT [FK_cars_car_transmission] FOREIGN KEY (cars_info_car_transmission) REFERENCES car_transmissions_lookup(car_transmission_type)
 -- There won't be frequent additions to the type of transmission. A CC would suffice instead of a lookup table
    ,CONSTRAINT [CC_cars_info_car_transmission_lookup] CHECK (cars_info_car_transmission = 'A' OR cars_info_car_transmission = 'M')
    ,CONSTRAINT [CC_cars_info_car_yearOfManf_range] CHECK (cars_info_car_yearOfManf >= 1992 AND cars_info_car_yearOfManf <= 2022)
    ,CONSTRAINT [CC_cars_info_car_fueltype_lookup] CHECK (cars_info_car_fueltype = 'GAS' OR cars_info_car_fueltype = 'ELE' OR cars_info_car_fueltype ='HYB')
    ,CONSTRAINT [CC_cars_info_car_mileage_000_range] CHECK (cars_info_car_mileage_000 > 0 )
    ,CONSTRAINT [CC_cars_info_car_noof_prev_owners] CHECK (cars_info_car_noof_prev_owners > 1)

)

-- Create the bid_status_lookup table that contains possible values for bid_status column in the bids table
GO -- Create bid_status_lookup table
CREATE TABLE bid_status_lookup(
     [bid_status_id] BIT NOT NULL PRIMARY KEY
    ,[bid_status_status] CHAR(3) NOT NULL

)

-- Create the bids table that contains information about bids placed on cars
GO -- Create the table
CREATE TABLE bids(
     [bid_id] SMALLINT NOT NULL IDENTITY(1,1)
    ,[bid_user_id] TINYINT NOT NULL
    ,[bid_car_id] TINYINT NOT NULL -- car_id's are assigned from 100-200
    ,[bid_date_time] DATETIME CONSTRAINT DF_bids_bid_date_time_current DEFAULT getdate()
    ,[bid_amount] SMALLMONEY NOT NULL -- Assuming we're only dealing cars that cost <214,748
    ,[bid_status] BIT NOT NULL -- 0=Not ok, 1=Ok
    ,CONSTRAINT [PK_bids_bid_id] PRIMARY KEY (bid_id)
    ,CONSTRAINT [FK_bids_bid_user_id] FOREIGN KEY (bid_user_id) REFERENCES users(user_id)
    ,CONSTRAINT [FK_bids_bid_car_id] FOREIGN KEY (bid_car_id) REFERENCES cars(car_id)
    -- ,CONSTRAINT [DF_bids_bid_date_time_current] DEFAULT bid_datetime (getdate())
    ,CONSTRAINT [CC_bids_bid_status] FOREIGN KEY (bid_status) REFERENCES bid_status_lookup(bid_status_id)
)

-- Create users_score_lookup
GO -- Create the table
CREATE TABLE score_provider_lookup(
    [provider_id] TINYINT NOT NULL PRIMARY KEY
    ,[provider_name] NVARCHAR(30) NOT NULL
)
-- Create users_score_lookup
GO -- Create the table
CREATE TABLE users_score_lookup(
    [users_score_id] TINYINT NOT NULL
    ,[users_score_user_id] TINYINT NOT NULL
    ,[users_score_user score] SMALLINT NOT NULL
    ,[users_score_provider_id] TINYINT NOT NULL
    ,CONSTRAINT [PK_users_score_id] PRIMARY KEY (users_score_id)
    ,CONSTRAINT [FK_users_score_user_id] FOREIGN KEY (users_score_user_id) REFERENCES users(user_id)
    ,CONSTRAINT [FK_users_score_provider_id] FOREIGN KEY (users_score_provider_id) REFERENCES score_provider_lookup(provider_id)
)
-- Create user_preferences
GO -- Create the table
CREATE TABLE users_preference(
    [preference_user_id] TINYINT NOT NULL
    ,[preference_max_price] SMALLMONEY NOT NULL
    ,[preference_color] NVARCHAR(20) NOT NULL
    ,[preference_fueltype] CHAR(3) NOT NULL -- GAS,EL,HY
    ,[preference_transmission] CHAR(1) -- A,M Automatic, Manual
    ,CONSTRAINT [PK_preference_user_id] PRIMARY KEY (preference_user_id)
    ,CONSTRAINT [FK_preference_user_id] FOREIGN KEY (preference_user_id) REFERENCES users(user_id)
)
-- Create car_ratings
GO -- Create the table
CREATE TABLE car_ratings(
    [rating_id] TINYINT NOT NULL
    ,[rating_for_car_id] TINYINT NOT NULL
    ,[rating_value] TINYINT NOT NULL
    ,[rating_comments] NVARCHAR NOT NULL
    ,CONSTRAINT [PK_CAR_RATINGS_RATING_ID] PRIMARY KEY (rating_id)
    ,CONSTRAINT [FK_CAR_RATINGS_FOR_CAR_ID] FOREIGN KEY (rating_for_car_id) REFERENCES cars(car_id)
)

PRINT('.....Tables created')

-- Inserting values into tables
GO
PRINT('Inserting Data into tables')
GO
INSERT INTO cartypes_lookup(cartype_type)
    VALUES ('Sedan'),('Coupe'),('Hatchback'),('SUV'),('Van')
GO
INSERT INTO car_conditions_lookup(car_conditions_condition)
    VALUES ('Bad'), ('Average'), ('Good'), ('Very Good'), ('Excellent') 
GO
INSERT INTO car_transmissions_lookup
    VALUES ('A'), ('M')
GO
INSERT INTO users
    (user_email, user_firstname, user_lastname, user_address_street, user_address_city
    , user_address_state,user_phonenumber_areacode, user_phonenumber_telephone, user_credit_score)
    VALUES
    ('rocio.walker@hotmail.com', 'Rocio', 'Walker', '46 Sunset St.', 'West Lafayette', 'IN',123,456789,769),
    ('nikita1@gmail.com', 'Nikita', 'One', '30 Longfellow St.', 'Egg Harbor Township', 'NJ',234,567890,680)
GO
INSERT INTO cars(car_name, car_type, car_asking_price, car_seller_user_id)
    VALUES ('Volvo XC60', 'SUV', 65000,1)

GO
select * from INFORMATION_SCHEMA.Tables
