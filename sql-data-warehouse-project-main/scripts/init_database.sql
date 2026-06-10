USE master; 
GO

/*
===============================================================================
Database Initialization Script
===============================================================================
Purpose:
    Creates the DataWarehouse database with all required schemas and
    enterprise infrastructure tables for audit logging, ETL metadata,
    data quality tracking, and data lineage.

Schemas:
    - bronze  : Raw landing layer (source-identical)
    - silver  : Cleaned, typed, standardized layer
    - gold    : Business-ready analytics layer (star schema)
    - audit   : ETL logging, error tracking, data quality, metadata

Author:     Anumodit Shukla
Created:    2025
Modified:   2026 — Enterprise upgrade
===============================================================================
*/

-- ============================================================================
-- 1. Create Database
-- ============================================================================

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- ============================================================================
-- 2. Create Schemas
-- ============================================================================

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO

CREATE SCHEMA audit;
GO

-- ============================================================================
-- 3. Audit Infrastructure — ETL Run Log
-- ============================================================================
-- Tracks every ETL procedure execution with timing and row counts.

CREATE TABLE audit.etl_run_log (
    run_id              INT IDENTITY(1,1)   PRIMARY KEY,
    batch_id            UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    procedure_name      NVARCHAR(255)       NOT NULL,
    layer               NVARCHAR(20)        NOT NULL,       -- bronze, silver, gold
    table_name          NVARCHAR(255)       NULL,
    status              NVARCHAR(20)        NOT NULL DEFAULT 'RUNNING',  -- RUNNING, SUCCESS, FAILED
    rows_affected       INT                 NULL,
    start_time          DATETIME2           NOT NULL DEFAULT SYSDATETIME(),
    end_time            DATETIME2           NULL,
    duration_seconds    AS DATEDIFF(SECOND, start_time, end_time),
    error_message       NVARCHAR(MAX)       NULL,
    created_by          NVARCHAR(128)       NOT NULL DEFAULT SUSER_SNAME()
);
GO

-- ============================================================================
-- 4. Audit Infrastructure — ETL Error Log
-- ============================================================================
-- Captures detailed error information from failed ETL runs.

CREATE TABLE audit.etl_error_log (
    error_id            INT IDENTITY(1,1)   PRIMARY KEY,
    run_id              INT                 NULL,
    batch_id            UNIQUEIDENTIFIER    NULL,
    error_number        INT                 NULL,
    error_severity      INT                 NULL,
    error_state         INT                 NULL,
    error_procedure     NVARCHAR(255)       NULL,
    error_line          INT                 NULL,
    error_message       NVARCHAR(MAX)       NULL,
    error_timestamp     DATETIME2           NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_error_log_run FOREIGN KEY (run_id)
        REFERENCES audit.etl_run_log(run_id)
);
GO

-- ============================================================================
-- 5. Audit Infrastructure — Data Quality Log
-- ============================================================================
-- Records results of all automated data quality checks.

CREATE TABLE audit.data_quality_log (
    check_id            INT IDENTITY(1,1)   PRIMARY KEY,
    batch_id            UNIQUEIDENTIFIER    NULL,
    check_name          NVARCHAR(255)       NOT NULL,
    layer               NVARCHAR(20)        NOT NULL,
    table_name          NVARCHAR(255)       NOT NULL,
    check_type          NVARCHAR(50)        NOT NULL,       -- NULL_CHECK, DUPLICATE, REFERENTIAL, BUSINESS_RULE, FRESHNESS, SCHEMA_DRIFT
    result_status       NVARCHAR(10)        NOT NULL,       -- PASS, FAIL, WARN
    records_affected    INT                 NULL DEFAULT 0,
    threshold           INT                 NULL,
    details             NVARCHAR(MAX)       NULL,
    check_timestamp     DATETIME2           NOT NULL DEFAULT SYSDATETIME()
);
GO

-- ============================================================================
-- 6. Audit Infrastructure — ETL Metadata
-- ============================================================================
-- Tracks load watermarks and table statistics for incremental processing.

CREATE TABLE audit.etl_metadata (
    metadata_id         INT IDENTITY(1,1)   PRIMARY KEY,
    table_name          NVARCHAR(255)       NOT NULL,
    layer               NVARCHAR(20)        NOT NULL,
    last_load_date      DATETIME2           NULL,
    last_watermark      NVARCHAR(255)       NULL,           -- Flexible watermark (date, ID, etc.)
    row_count           BIGINT              NULL,
    load_type           NVARCHAR(20)        NOT NULL DEFAULT 'FULL',  -- FULL, INCREMENTAL, CDC
    is_active           BIT                 NOT NULL DEFAULT 1,
    created_date        DATETIME2           NOT NULL DEFAULT SYSDATETIME(),
    modified_date       DATETIME2           NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT UQ_metadata_table_layer UNIQUE (table_name, layer)
);
GO

-- ============================================================================
-- 7. Audit Infrastructure — Data Lineage
-- ============================================================================
-- Documents the transformation lineage from source to target.

CREATE TABLE audit.data_lineage (
    lineage_id          INT IDENTITY(1,1)   PRIMARY KEY,
    source_schema       NVARCHAR(50)        NOT NULL,
    source_table        NVARCHAR(255)       NOT NULL,
    target_schema       NVARCHAR(50)        NOT NULL,
    target_table        NVARCHAR(255)       NOT NULL,
    transformation_type NVARCHAR(50)        NOT NULL,       -- DIRECT_COPY, TYPE_CAST, DERIVATION, AGGREGATION, SCD2_MERGE
    column_mapping      NVARCHAR(MAX)       NULL,           -- JSON mapping of source→target columns
    business_rule       NVARCHAR(MAX)       NULL,
    created_date        DATETIME2           NOT NULL DEFAULT SYSDATETIME(),
    modified_date       DATETIME2           NOT NULL DEFAULT SYSDATETIME()
);
GO

-- ============================================================================
-- 8. Seed ETL Metadata for All Tables
-- ============================================================================

INSERT INTO audit.etl_metadata (table_name, layer, load_type)
VALUES
    ('application_train',   'bronze', 'FULL'),
    ('application_test',    'bronze', 'FULL'),
    ('bureau',              'bronze', 'FULL'),
    ('bureau_balance',      'bronze', 'FULL'),
    ('previous_application','bronze', 'FULL'),
    ('installments_payments','bronze','FULL'),
    ('POS_CASH_balance',    'bronze', 'FULL'),
    ('credit_card_balance', 'bronze', 'FULL'),
    ('application_train',   'silver', 'FULL'),
    ('application_test',    'silver', 'FULL'),
    ('bureau',              'silver', 'FULL'),
    ('bureau_balance',      'silver', 'FULL'),
    ('previous_application','silver', 'FULL'),
    ('installments_payments','silver','FULL'),
    ('POS_CASH_balance',    'silver', 'FULL'),
    ('credit_card_balance', 'silver', 'FULL'),
    ('dim_customer',        'gold',  'FULL'),
    ('dim_time',            'gold',  'FULL'),
    ('dim_credit',          'gold',  'FULL'),
    ('dim_region',          'gold',  'FULL'),
    ('dim_income',          'gold',  'FULL'),
    ('fact_loan_application','gold', 'FULL'),
    ('fact_payment_behavior','gold', 'FULL'),
    ('fact_credit_history', 'gold',  'FULL'),
    ('fact_default_events', 'gold',  'FULL');
GO

-- ============================================================================
-- 9. Seed Data Lineage Records
-- ============================================================================

INSERT INTO audit.data_lineage (source_schema, source_table, target_schema, target_table, transformation_type, business_rule)
VALUES
    ('CSV',    'application_train.csv',  'bronze', 'application_train',   'DIRECT_COPY',  'BULK INSERT with NVARCHAR landing'),
    ('CSV',    'application_test.csv',   'bronze', 'application_test',    'DIRECT_COPY',  'BULK INSERT with NVARCHAR landing'),
    ('CSV',    'bureau.csv',             'bronze', 'bureau',              'DIRECT_COPY',  'BULK INSERT with NVARCHAR landing'),
    ('CSV',    'bureau_balance.csv',     'bronze', 'bureau_balance',      'DIRECT_COPY',  'BULK INSERT with NVARCHAR landing'),
    ('CSV',    'previous_application.csv','bronze','previous_application','DIRECT_COPY',  'BULK INSERT with NVARCHAR landing'),
    ('CSV',    'installments_payments.csv','bronze','installments_payments','DIRECT_COPY', 'BULK INSERT with NVARCHAR landing'),
    ('CSV',    'POS_CASH_balance.csv',   'bronze', 'POS_CASH_balance',   'DIRECT_COPY',  'BULK INSERT with NVARCHAR landing'),
    ('CSV',    'credit_card_balance.csv','bronze', 'credit_card_balance', 'DIRECT_COPY',  'BULK INSERT with NVARCHAR landing'),
    ('bronze', 'application_train',      'silver', 'application_train',  'TYPE_CAST',    'TRY_CAST, NULLIF, categorical standardization, derived ratios'),
    ('bronze', 'application_test',       'silver', 'application_test',   'TYPE_CAST',    'TRY_CAST, NULLIF, categorical standardization'),
    ('bronze', 'bureau',                 'silver', 'bureau',             'TYPE_CAST',    'TRY_CAST, overdue_flag derivation, credit_debt_ratio'),
    ('bronze', 'bureau_balance',         'silver', 'bureau_balance',     'TYPE_CAST',    'TRY_CAST, status_group classification'),
    ('bronze', 'previous_application',   'silver', 'previous_application','TYPE_CAST',   'TRY_CAST, categorical cleaning'),
    ('bronze', 'installments_payments',  'silver', 'installments_payments','TYPE_CAST',  'TRY_CAST, payment_difference, payment_delay_days, flags'),
    ('bronze', 'POS_CASH_balance',       'silver', 'POS_CASH_balance',   'TYPE_CAST',    'TRY_CAST, dpd_flag derivation'),
    ('bronze', 'credit_card_balance',    'silver', 'credit_card_balance','TYPE_CAST',    'TRY_CAST, credit_utilization_ratio, dpd_flag'),
    ('silver', 'application_train',      'gold',   'dim_customer',      'SCD2_MERGE',   'SCD Type 2 with effective/end dates'),
    ('silver', 'application_train',      'gold',   'fact_loan_application','AGGREGATION','Surrogate key lookups to all dimensions'),
    ('silver', 'installments_payments',  'gold',   'fact_payment_behavior','AGGREGATION','Customer-level payment aggregation'),
    ('silver', 'bureau',                 'gold',   'fact_credit_history','AGGREGATION',  'Customer-level bureau aggregation'),
    ('silver', 'application_train',      'gold',   'fact_default_events','DERIVATION',   'Default event extraction with risk scoring');
GO

PRINT '================================================';
PRINT 'Database initialization completed successfully.';
PRINT 'Schemas created: bronze, silver, gold, audit';
PRINT 'Audit tables: etl_run_log, etl_error_log, data_quality_log, etl_metadata, data_lineage';
PRINT '================================================';
GO
