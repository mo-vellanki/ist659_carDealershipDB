USE master
-- DOWN
-- Drop the cars table if it already exists
GO
DROP TABLE IF EXISTS dbo.cars

--UP

GO -- Create the new database if it does not exist already
IF NOT EXISTS (
    SELECT [name]
        FROM sys.databases
        WHERE [name] = N'carDealershipDB'
)
CREATE DATABASE carDealershipDB

USE carDealershipDB;
GO -- Create the table
-- Create the cars table that contains information about a car
CREATE TABLE dbo.cars
(
     [car_id] INT NOT NULL IDENTITY(100,1)
    ,[car_name] NVARCHAR(50) NOT NULL
    ,[car_type] NVARCHAR(50) NOT NULL
    ,[car_desctiption] NVARCHAR(100) NOT NULL
    ,[car_available] BIT NOT NULL -- 0=False, 1=True if car is available or not
    ,[car_asking_price] SMALLMONEY NOT NULL -- Assuming we're only dealing cars that cost <214,748
    ,[car_seller_user_id] TINYINT NOT NULL
    ,[car_buyer_user_id] TINYINT NOT NULL
    ,[car_amount_sold] SMALLMONEY NOT NULL -- Assuming we're only dealing cars that cost <214,748
    ,CONSTRAINT pk_cars_car_id primary key (car_id)
    ,CONSTRAINT ck_cars_seller_isnot_buyer CHECK (car_seller_user_id != car_buyer_user_id)
)

GO -- Create the 
