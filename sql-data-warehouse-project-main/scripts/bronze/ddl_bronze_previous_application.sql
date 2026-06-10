USE DataWarehouse;
GO

/*
===============================================================================
DDL Script: Bronze Layer - Previous Application Table
===============================================================================
Script Purpose:
    Creates raw bronze table for previous loan applications.

Important Design Rules:
    - Bronze = raw landing layer
    - All columns stored as NVARCHAR
    - No datatype conversion
    - No constraints / PK / FK
    - Includes audit column dwh_load_date
===============================================================================
*/

DROP TABLE IF EXISTS bronze.previous_application;
GO

CREATE TABLE bronze.previous_application (

    SK_ID_PREV NVARCHAR(255),
    SK_ID_CURR NVARCHAR(255),

    NAME_CONTRACT_TYPE NVARCHAR(255),

    AMT_ANNUITY NVARCHAR(255),
    AMT_APPLICATION NVARCHAR(255),
    AMT_CREDIT NVARCHAR(255),
    AMT_DOWN_PAYMENT NVARCHAR(255),
    AMT_GOODS_PRICE NVARCHAR(255),

    WEEKDAY_APPR_PROCESS_START NVARCHAR(255),
    HOUR_APPR_PROCESS_START NVARCHAR(255),

    FLAG_LAST_APPL_PER_CONTRACT NVARCHAR(255),
    NFLAG_LAST_APPL_IN_DAY NVARCHAR(255),

    RATE_DOWN_PAYMENT NVARCHAR(255),
    RATE_INTEREST_PRIMARY NVARCHAR(255),
    RATE_INTEREST_PRIVILEGED NVARCHAR(255),

    NAME_CASH_LOAN_PURPOSE NVARCHAR(255),

    NAME_CONTRACT_STATUS NVARCHAR(255),

    DAYS_DECISION NVARCHAR(255),

    NAME_PAYMENT_TYPE NVARCHAR(255),

    CODE_REJECT_REASON NVARCHAR(255),

    NAME_TYPE_SUITE NVARCHAR(255),

    NAME_CLIENT_TYPE NVARCHAR(255),

    NAME_GOODS_CATEGORY NVARCHAR(255),

    NAME_PORTFOLIO NVARCHAR(255),

    NAME_PRODUCT_TYPE NVARCHAR(255),

    CHANNEL_TYPE NVARCHAR(255),

    SELLERPLACE_AREA NVARCHAR(255),

    NAME_SELLER_INDUSTRY NVARCHAR(255),

    CNT_PAYMENT NVARCHAR(255),

    NAME_YIELD_GROUP NVARCHAR(255),

    PRODUCT_COMBINATION NVARCHAR(255),

    DAYS_FIRST_DRAWING NVARCHAR(255),
    DAYS_FIRST_DUE NVARCHAR(255),
    DAYS_LAST_DUE_1ST_VERSION NVARCHAR(255),
    DAYS_LAST_DUE NVARCHAR(255),
    DAYS_TERMINATION NVARCHAR(255),

    NFLAG_INSURED_ON_APPROVAL NVARCHAR(255),

    dwh_load_date DATETIME2 DEFAULT GETDATE()

);
GO