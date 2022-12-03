USE master
-- DOWN

--DROP the FK constraints
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_cars_car_type')
    ALTER TABLE cars DROP CONSTRAINT FK_cars_car_type
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_cars_car_condition')
    ALTER TABLE cars DROP CONSTRAINT FK_cars_car_condition
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_cars_car_transmission')
    ALTER TABLE cars DROP CONSTRAINT FK_cars_car_transmission
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_cars_car_seller_user_id')
    ALTER TABLE cars DROP CONSTRAINT FK_cars_car_seller_user_id
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_cars_car_buyer_user_id')
    ALTER TABLE cars DROP CONSTRAINT FK_cars_car_buyer_user_id
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_cars_car_buyer_user_id')
    ALTER TABLE cars DROP CONSTRAINT FK_cars_car_buyer_user_id
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
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_preference_user_id')
    ALTER TABLE users_preference DROP CONSTRAINT FK_preference_user_id
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_CAR_RATINGS_FOR_CAR_ID')
    ALTER TABLE car_ratings DROP CONSTRAINT FK_CAR_RATINGS_FOR_CAR_ID
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_users_user_credit_score_id')
    ALTER TABLE users DROP CONSTRAINT FK_users_user_credit_score_id
PRINT('Dropped existing constraints')

-- Drop the views if they already exist
GO
DROP VIEW IF EXISTS v_cars_avail_basedon_user_preference
PRINT('Dropped existing views')

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
    ,[user_credit_score_id] SMALLINT NOT NULL
    ,CONSTRAINT [PK_users_user_id] PRIMARY KEY (user_id)
    ,CONSTRAINT [FK_users_user_credit_score_id] FOREIGN KEY (user_credit_score_id) REFERENCES users_score_lookup(users_score_user_id)
    ,CONSTRAINT [UC_users_user_email] UNIQUE (user_email)
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
    ,[car_sell_by] DATETIME NOT NULL CONSTRAINT DV_cars_car_sell_by DEFAULT (DATEADD(day, 30, GETDATE())) -- Bidding period for each car is 30days
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
     [bid_status_id] BIT NOT NULL
    ,[bid_status_status] CHAR(3) NOT NULL
    ,CONSTRAINT [PK_bid_status_lookup] PRIMARY KEY (bid_status_id)
    ,CONSTRAINT [U_bid_status_status] UNIQUE (bid_status_status)
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
    ,CONSTRAINT [FK_bids_bid_status] FOREIGN KEY (bid_status) REFERENCES bid_status_lookup(bid_status_id)
)

-- Create users_score_lookup
GO -- Create the table
CREATE TABLE score_provider_lookup(
    [provider_id] TINYINT NOT NULL IDENTITY(1,1)
    ,[provider_name] NVARCHAR(30) NOT NULL
    ,CONSTRAINT [PK_score_provider_lookup_provider_id] PRIMARY KEY (provider_id)
)
-- Create users_score_lookup
GO -- Create the table
CREATE TABLE users_score_lookup(
    [users_score_id] TINYINT NOT NULL IDENTITY(1,1)
    [users_score_user_id] TINYINT NOT NULL
    ,[users_score_credit_score] SMALLINT NOT NULL
    ,[users_score_provider_id] TINYINT NOT NULL
    ,CONSTRAINT [PK_users_score_id] PRIMARY KEY (users_score_id)
    ,CONSTRAINT [FK_users_score_user_id] FOREIGN KEY (users_score_user_id) REFERENCES users(user_id)
    ,CONSTRAINT [FK_users_score_provider_id] FOREIGN KEY (users_score_provider_id) REFERENCES score_provider_lookup(provider_id)
    ,CONSTRAINT [CC_user_credit_score_range] CHECK (users_score_credit_score >=300 AND users_score_credit_score<=850)

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
    [rating_id] TINYINT NOT NULL IDENTITY(1,1)
    ,[rating_for_car_id] TINYINT NOT NULL
    ,[rating_value] TINYINT NOT NULL
    ,[rating_comments] NVARCHAR NOT NULL
    ,CONSTRAINT [PK_CAR_RATINGS_RATING_ID] PRIMARY KEY (rating_id)
    ,CONSTRAINT [FK_CAR_RATINGS_FOR_CAR_ID] FOREIGN KEY (rating_for_car_id) REFERENCES cars(car_id)
)
GO
PRINT('.....Tables created')

-- Inserting values into tables
GO
PRINT('Inserting Data into tables')
GO
INSERT INTO users
    (user_email, user_firstname, user_lastname, user_address_street, user_address_city
    , user_address_state,user_phonenumber_areacode, user_phonenumber_telephone, user_credit_score_id)
    VALUES
    ('roy.walker@hotmail.com', 'Roy', 'Walker', '45 Sunset St.', 'East Lafayette', 'IN',134,456745,1)
    ,('nate@gmail.com', 'Nate', 'Turner', '50 Longfellow St.', 'Harbor Township', 'NJ',235,567890,680)
    ,('joy.alan@hotmail.com', 'Joy', 'Alan', '50 Sunset St.', 'East Lafayette', 'IN',134,496745,756)
    ,('grace.smith@hotmail.com', 'Grace', 'Smith', '67 Sunset St.', 'East Lafayette', 'IN',134,458945,766)

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
INSERT INTO cars(car_name, car_type, car_asking_price, car_seller_user_id)
    VALUES ('Volvo XC60', 'SUV', 65000,1)
INSERT INTO cars(car_name, car_type, car_asking_price, car_seller_user_id)
    VALUES ('Hyndai IONIQ', 'Sedan', 50000,2)
INSERT INTO cars(car_name, car_type, car_asking_price, car_seller_user_id)
    VALUES ('Nissan Rogue Hybrid 2019', 'SUV', 65000,2)
INSERT INTO cars(car_name, car_type, car_asking_price, car_seller_user_id)
    VALUES ('Toyoto GR86', 'Coupe', 55000,1)
INSERT INTO cars(car_name, car_type, car_asking_price, car_seller_user_id)
    VALUES ('Subaru Crosstrek', 'Hatchback', 45000,1)
INSERT INTO cars(car_name, car_type, car_asking_price, car_seller_user_id)
    VALUES ('Volvo XC60', 'SUV', 65000,1)
INSERT INTO cars(car_name, car_type, car_asking_price, car_seller_user_id)
    VALUES ('Honda Sienna', 'Van', 65000,1)
GO
INSERT INTO cars_information
    (cars_info_car_id,cars_info_car_description,cars_info_car_transmission,cars_info_car_colour,
    cars_info_car_yearOfManf,cars_info_car_fueltype,cars_info_car_mileage_000,cars_info_car_noof_prev_owners,cars_info_car_condition)
    VALUES
    (100,'Intelligent design at every turn. Meet our smart midsize SUV with Google built-in','A','Red',2020,'ELE',4,2,5)
    ,(101,'Discover inner harmony. Contemporary design and more sustainable materials characterize every detail','A','Red',2020,'ELE',31,2,5)
    ,(102,'Good Condition','A','black',2001,'GAS',3,2,4)
    ,(103,'Spacious','M','Blue',2011,'HYB',1,2,5)
    ,(104,'Inner Harmony' ,'A','yellow',2013,'GAS',11,8,5)
    ,(105,'Contemporary design and more sustainable materials characterize every detail','A','Red',2020,'ELE',13,7,5)
    ,(106,'inner harmony. Contemporary design','M','green',2020,'HYB',24,8,4)
    -- ,(107,'Discover inner harmony. Contemporary design more sustainable materials characterize every detail','M','Red',2020,'HYB',5,4,2)
    -- ,(108,' sustainable materials characterize every detail','A','Blue',2020,'ELE',3,2,2)
    -- ,(109,'Contemporary design','A','Black',2020,'GAS',31,3,4)
GO
INSERT INTO bid_status_lookup VALUES (0, 'NOK') ,(1, 'OK')-- , (4,'OK')

GO
INSERT INTO bids (bid_user_id,bid_car_id,bid_amount,bid_status)
    VALUES (1,100,100000,0)
            ,(2,101,65000,1)
            ,(3,102,70000,0)
            ,(4,104,80000,1)
GO
INSERT INTO score_provider_lookup(provider_name) values ('Equifax'),('TransUnion'),('Experian')
GO
INSERT INTO users_score_lookup(users_score_user_id,users_score_credit_score,users_score_provider_id)
    VALUES (1, 600, 2)
            ,(2, 800, 1)
            ,(3, 740, 3)
            ,(4, 690, 2)

GO
INSERT INTO users_preference(preference_user_id,preference_max_price,preference_color,preference_fueltype,preference_transmission)
    VALUES (3,28000,'Green','HYB','A')
            ,(1,18000,'Red','HYB','A')
            ,(2,28000,'Green','ELE','A')
            ,(4,29000,'Green','HYB','A')
            --,(5,28000,'Blue','HYB','A')

GO
INSERT INTO car_ratings(rating_id,rating_for_car_id,rating_value,rating_comments)
    VALUES (1,100,4,'Mint condition')
            ,(2,102,2,'Needs some fixes')
            ,(3,103,3,'Runs fine with random noises')
            ,(4,107,5,'excellent')

GO
PRINT('.....Data inserted')