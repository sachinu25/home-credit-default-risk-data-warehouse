USE DataWarehouse;
GO

/*
===============================================================================
DDL Script: Bronze Layer - Payments and Balance Tables
===============================================================================
Script Purpose:
    Creates raw bronze tables for:
    - installments_payments
    - POS_CASH_balance
    - credit_card_balance

Important Design Rules:
    - Bronze = raw landing layer
    - All columns stored as NVARCHAR
    - No datatype conversion
    - No constraints / PK / FK
    - Includes audit column dwh_load_date
===============================================================================
*/

DROP TABLE IF EXISTS bronze.credit_card_balance;
DROP TABLE IF EXISTS bronze.POS_CASH_balance;
DROP TABLE IF EXISTS bronze.installments_payments;
GO

/*
===============================================================================
installments_payments
===============================================================================
*/

CREATE TABLE bronze.installments_payments (

    SK_ID_PREV NVARCHAR(255),

    SK_ID_CURR NVARCHAR(255),

    NUM_INSTALMENT_VERSION NVARCHAR(255),

    NUM_INSTALMENT_NUMBER NVARCHAR(255),

    DAYS_INSTALMENT NVARCHAR(255),

    DAYS_ENTRY_PAYMENT NVARCHAR(255),

    AMT_INSTALMENT NVARCHAR(255),

    AMT_PAYMENT NVARCHAR(255),

    dwh_load_date DATETIME2 DEFAULT GETDATE()

);
GO

/*
===============================================================================
POS_CASH_balance
===============================================================================
*/

CREATE TABLE bronze.POS_CASH_balance (

    SK_ID_PREV NVARCHAR(255),

    SK_ID_CURR NVARCHAR(255),

    MONTHS_BALANCE NVARCHAR(255),

    CNT_INSTALMENT NVARCHAR(255),

    CNT_INSTALMENT_FUTURE NVARCHAR(255),

    NAME_CONTRACT_STATUS NVARCHAR(255),

    SK_DPD NVARCHAR(255),

    SK_DPD_DEF NVARCHAR(255),

    dwh_load_date DATETIME2 DEFAULT GETDATE()

);
GO

/*
===============================================================================
credit_card_balance
===============================================================================
*/

CREATE TABLE bronze.credit_card_balance (

    SK_ID_PREV NVARCHAR(255),

    SK_ID_CURR NVARCHAR(255),

    MONTHS_BALANCE NVARCHAR(255),

    AMT_BALANCE NVARCHAR(255),

    AMT_CREDIT_LIMIT_ACTUAL NVARCHAR(255),

    AMT_DRAWINGS_ATM_CURRENT NVARCHAR(255),

    AMT_DRAWINGS_CURRENT NVARCHAR(255),

    AMT_DRAWINGS_OTHER_CURRENT NVARCHAR(255),

    AMT_DRAWINGS_POS_CURRENT NVARCHAR(255),

    AMT_INST_MIN_REGULARITY NVARCHAR(255),

    AMT_PAYMENT_CURRENT NVARCHAR(255),

    AMT_PAYMENT_TOTAL_CURRENT NVARCHAR(255),

    AMT_RECEIVABLE_PRINCIPAL NVARCHAR(255),

    AMT_RECIVABLE NVARCHAR(255),

    AMT_TOTAL_RECEIVABLE NVARCHAR(255),

    CNT_DRAWINGS_ATM_CURRENT NVARCHAR(255),

    CNT_DRAWINGS_CURRENT NVARCHAR(255),

    CNT_DRAWINGS_OTHER_CURRENT NVARCHAR(255),

    CNT_DRAWINGS_POS_CURRENT NVARCHAR(255),

    CNT_INSTALMENT_MATURE_CUM NVARCHAR(255),

    NAME_CONTRACT_STATUS NVARCHAR(255),

    SK_DPD NVARCHAR(255),

    SK_DPD_DEF NVARCHAR(255),

    dwh_load_date DATETIME2 DEFAULT GETDATE()

);
GO