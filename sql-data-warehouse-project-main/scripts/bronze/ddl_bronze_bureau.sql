USE DataWarehouse;
GO

/*
===============================================================================
DDL Script: Bronze Layer - Bureau Tables
===============================================================================
Script Purpose:
    Creates raw bronze tables for bureau datasets.

Important Design Rules:
    - Bronze = raw landing layer
    - All columns stored as NVARCHAR
    - No datatype conversion
    - No constraints / PK / FK
    - Includes audit column dwh_load_date
===============================================================================
*/

DROP TABLE IF EXISTS bronze.bureau_balance;
DROP TABLE IF EXISTS bronze.bureau;
GO

/*
===============================================================================
bureau
===============================================================================
*/

CREATE TABLE bronze.bureau (

    SK_ID_CURR NVARCHAR(255),
    SK_ID_BUREAU NVARCHAR(255),

    CREDIT_ACTIVE NVARCHAR(255),
    CREDIT_CURRENCY NVARCHAR(255),

    DAYS_CREDIT NVARCHAR(255),
    CREDIT_DAY_OVERDUE NVARCHAR(255),

    DAYS_CREDIT_ENDDATE NVARCHAR(255),
    DAYS_ENDDATE_FACT NVARCHAR(255),

    AMT_CREDIT_MAX_OVERDUE NVARCHAR(255),

    CNT_CREDIT_PROLONG NVARCHAR(255),

    AMT_CREDIT_SUM NVARCHAR(255),
    AMT_CREDIT_SUM_DEBT NVARCHAR(255),
    AMT_CREDIT_SUM_LIMIT NVARCHAR(255),
    AMT_CREDIT_SUM_OVERDUE NVARCHAR(255),

    CREDIT_TYPE NVARCHAR(255),

    DAYS_CREDIT_UPDATE NVARCHAR(255),

    AMT_ANNUITY NVARCHAR(255),

    dwh_load_date DATETIME2 DEFAULT GETDATE()

);
GO

/*
===============================================================================
bureau_balance
===============================================================================
*/

CREATE TABLE bronze.bureau_balance (

    SK_ID_BUREAU NVARCHAR(255),

    MONTHS_BALANCE NVARCHAR(255),

    STATUS NVARCHAR(255),

    dwh_load_date DATETIME2 DEFAULT GETDATE()

);
GO