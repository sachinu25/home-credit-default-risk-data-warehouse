USE DataWarehouse;
GO

/*
===============================================================================
DDL Script: Bronze Layer - Reference Tables
===============================================================================
Script Purpose:
    Creates raw bronze reference/helper tables.

Tables:
    - HomeCredit_columns_description
    - sample_submission

Important Design Rules:
    - Bronze = raw landing layer
    - All columns stored as NVARCHAR
    - No datatype conversion
    - No constraints / PK / FK
    - Includes audit column dwh_load_date
===============================================================================
*/

DROP TABLE IF EXISTS bronze.HomeCredit_columns_description;
DROP TABLE IF EXISTS bronze.sample_submission;
GO

/*
===============================================================================
HomeCredit_columns_description
===============================================================================
*/

CREATE TABLE bronze.HomeCredit_columns_description (

    [Row] NVARCHAR(255),

    [Table] NVARCHAR(255),

    [Column] NVARCHAR(255),

    [Description] NVARCHAR(MAX),

    [Special] NVARCHAR(MAX),

    dwh_load_date DATETIME2 DEFAULT GETDATE()

);
GO

/*
===============================================================================
sample_submission
===============================================================================
*/

CREATE TABLE bronze.sample_submission (

    SK_ID_CURR NVARCHAR(255),

    TARGET NVARCHAR(255),

    dwh_load_date DATETIME2 DEFAULT GETDATE()

);
GO