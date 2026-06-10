USE DataWarehouse;
GO

/*
===============================================================================
DDL Script: Gold Fact Tables — Enterprise Star Schema
===============================================================================
Purpose:
    Creates production-grade fact TABLES for the Gold layer star schema.
    Each fact table references dimension surrogate keys and contains
    measurable business metrics.

Design Principles:
    ✓ Foreign keys to all relevant dimensions
    ✓ Additive, semi-additive, and non-additive measures
    ✓ Grain documented for each table
    ✓ Optimized for analytical queries

Fact Tables:
    1. gold.fact_loan_application  — Core lending application facts
    2. gold.fact_payment_behavior  — Payment pattern aggregation
    3. gold.fact_credit_history    — Bureau credit history aggregation
    4. gold.fact_default_events    — Default event tracking

Author:     Anumodit Shukla
Created:    2025
Modified:   2026 — Enterprise star schema with proper fact tables
===============================================================================
*/

-- ============================================================================
-- Drop Existing Objects
-- ============================================================================

DROP VIEW  IF EXISTS gold.fact_credit_history;
DROP VIEW  IF EXISTS gold.fact_payment_behavior;
DROP VIEW  IF EXISTS gold.fact_loan_application;
DROP TABLE IF EXISTS gold.fact_default_events;
DROP TABLE IF EXISTS gold.fact_credit_history;
DROP TABLE IF EXISTS gold.fact_payment_behavior;
DROP TABLE IF EXISTS gold.fact_loan_application;
GO

/*
===============================================================================
Fact 1: fact_loan_application
===============================================================================
Purpose:
    Central fact table storing loan application-level financial metrics
    and risk indicators. This is the primary grain for portfolio analysis.

Grain:
    1 row = 1 loan application (1 customer = 1 application)

Measures (all additive):
    - income_total, credit_amount, annuity_amount, goods_price
    - credit_income_ratio, annuity_income_ratio, goods_credit_ratio

Dimension Keys:
    - customer_key  → gold.dim_customer
    - time_key      → gold.dim_time (application date)
    - region_key    → gold.dim_region
    - income_key    → gold.dim_income
===============================================================================
*/

CREATE TABLE gold.fact_loan_application (

    loan_application_key    INT IDENTITY(1,1)   PRIMARY KEY,

    -- Dimension Foreign Keys
    customer_key            INT                 NOT NULL,
    time_key                INT                 NULL,
    region_key              INT                 NULL,
    income_key              INT                 NULL,

    -- Business Key
    customer_id             INT                 NOT NULL,

    -- Default Indicator
    default_flag            TINYINT             NULL,         -- 0 = No Default, 1 = Default

    -- Contract Information
    contract_type           NVARCHAR(50)        NULL,

    -- Financial Measures (Additive)
    income_total            DECIMAL(18,2)       NULL,
    credit_amount           DECIMAL(18,2)       NULL,
    annuity_amount          DECIMAL(18,2)       NULL,
    goods_price             DECIMAL(18,2)       NULL,

    -- Derived Ratios (Semi-Additive — use AVG/WEIGHTED AVG)
    credit_income_ratio     DECIMAL(18,4)       NULL,
    annuity_income_ratio    DECIMAL(18,4)       NULL,
    goods_credit_ratio      DECIMAL(18,4)       NULL,

    -- Employment
    employment_years        DECIMAL(8,2)        NULL,

    -- External Risk Scores
    ext_source_1            DECIMAL(18,10)      NULL,
    ext_source_2            DECIMAL(18,10)      NULL,
    ext_source_3            DECIMAL(18,10)      NULL,

    -- Composite Risk Score
    composite_risk_score    DECIMAL(10,4)       NULL,

    -- Risk Segment
    risk_segment            NVARCHAR(20)        NULL,

    -- Credit Bureau Activity
    req_credit_bureau_hour      DECIMAL(10,2)   NULL,
    req_credit_bureau_day       DECIMAL(10,2)   NULL,
    req_credit_bureau_week      DECIMAL(10,2)   NULL,
    req_credit_bureau_month     DECIMAL(10,2)   NULL,
    req_credit_bureau_quarter   DECIMAL(10,2)   NULL,
    req_credit_bureau_year      DECIMAL(10,2)   NULL,

    -- Metadata
    dwh_load_date           DATETIME2           NOT NULL DEFAULT SYSDATETIME(),

    -- Foreign Key Constraints
    CONSTRAINT FK_fact_loan_customer FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customer(customer_key),
    CONSTRAINT FK_fact_loan_time FOREIGN KEY (time_key)
        REFERENCES gold.dim_time(time_key),
    CONSTRAINT FK_fact_loan_region FOREIGN KEY (region_key)
        REFERENCES gold.dim_region(region_key),
    CONSTRAINT FK_fact_loan_income FOREIGN KEY (income_key)
        REFERENCES gold.dim_income(income_key)
);
GO

/*
===============================================================================
Fact 2: fact_payment_behavior
===============================================================================
Purpose:
    Aggregated payment behavior metrics at the customer level.
    Tracks payment patterns, delinquency, and completion ratios.

Grain:
    1 row = 1 customer (aggregated from installments_payments)

Measures:
    - total_installments (additive)
    - late_payment_count (additive)
    - payment_completion_ratio (semi-additive — use AVG)
===============================================================================
*/

CREATE TABLE gold.fact_payment_behavior (

    payment_behavior_key    INT IDENTITY(1,1)   PRIMARY KEY,

    -- Dimension Foreign Keys
    customer_key            INT                 NOT NULL,

    -- Business Key
    customer_id             INT                 NOT NULL,

    -- Volume Measures (Additive)
    total_installments      INT                 NULL,
    late_payment_count      INT                 NULL,
    underpaid_count         INT                 NULL,
    on_time_payment_count   INT                 NULL,

    -- Payment Delay Measures
    avg_payment_delay_days  DECIMAL(10,2)       NULL,
    max_payment_delay_days  DECIMAL(10,2)       NULL,
    min_payment_delay_days  DECIMAL(10,2)       NULL,

    -- Amount Measures (Additive)
    avg_payment_difference  DECIMAL(18,2)       NULL,
    total_payment_amount    DECIMAL(18,2)       NULL,
    total_instalment_amount DECIMAL(18,2)       NULL,

    -- Derived Ratios
    payment_completion_ratio    DECIMAL(10,4)   NULL,
    late_payment_ratio          DECIMAL(10,4)   NULL,
    underpaid_ratio             DECIMAL(10,4)   NULL,

    -- Payment Health Score (0-100, higher = better)
    payment_health_score    DECIMAL(5,2)        NULL,

    -- Metadata
    dwh_load_date           DATETIME2           NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_fact_payment_customer FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customer(customer_key)
);
GO

/*
===============================================================================
Fact 3: fact_credit_history
===============================================================================
Purpose:
    Aggregated credit bureau history metrics at the customer level.
    Tracks credit exposure, overdue accounts, and utilization.

Grain:
    1 row = 1 customer (aggregated from bureau)

Measures:
    - total_bureau_records (additive)
    - total_credit_sum (additive)
    - avg_credit_debt_ratio (semi-additive)
===============================================================================
*/

CREATE TABLE gold.fact_credit_history (

    credit_history_key      INT IDENTITY(1,1)   PRIMARY KEY,

    -- Dimension Foreign Keys
    customer_key            INT                 NOT NULL,

    -- Business Key
    customer_id             INT                 NOT NULL,

    -- Volume Measures
    total_bureau_records    INT                 NULL,
    active_credit_count     INT                 NULL,
    closed_credit_count     INT                 NULL,
    overdue_credit_count    INT                 NULL,

    -- Amount Measures (Additive)
    total_credit_sum        DECIMAL(18,2)       NULL,
    total_credit_debt       DECIMAL(18,2)       NULL,
    total_credit_overdue    DECIMAL(18,2)       NULL,
    total_credit_limit      DECIMAL(18,2)       NULL,

    -- Derived Ratios
    avg_credit_debt_ratio   DECIMAL(10,4)       NULL,
    credit_utilization      DECIMAL(10,4)       NULL,
    overdue_ratio           DECIMAL(10,4)       NULL,

    -- Credit Health Score (0-100, higher = better)
    credit_health_score     DECIMAL(5,2)        NULL,

    -- Metadata
    dwh_load_date           DATETIME2           NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_fact_credit_customer FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customer(customer_key)
);
GO

/*
===============================================================================
Fact 4: fact_default_events
===============================================================================
Purpose:
    Event-based fact table tracking default occurrences with full context.
    Enables default pattern analysis, cohort tracking, and loss estimation.

Grain:
    1 row = 1 default event (only customers with default_flag = 1)

Business Usage:
    - Default rate trending
    - Loss given default estimation
    - Exposure at default analysis
    - Risk factor correlation
===============================================================================
*/

CREATE TABLE gold.fact_default_events (

    default_event_key       INT IDENTITY(1,1)   PRIMARY KEY,

    -- Dimension Foreign Keys
    customer_key            INT                 NOT NULL,
    time_key                INT                 NULL,
    region_key              INT                 NULL,
    income_key              INT                 NULL,

    -- Business Key
    customer_id             INT                 NOT NULL,

    -- Default Context
    default_flag            TINYINT             NOT NULL DEFAULT 1,
    
    -- Exposure at Default (EAD)
    credit_amount           DECIMAL(18,2)       NULL,
    outstanding_balance     DECIMAL(18,2)       NULL,
    
    -- Loss Given Default Factors
    annuity_amount          DECIMAL(18,2)       NULL,
    income_total            DECIMAL(18,2)       NULL,
    goods_price             DECIMAL(18,2)       NULL,

    -- Risk Factors at Time of Default
    credit_income_ratio     DECIMAL(18,4)       NULL,
    annuity_income_ratio    DECIMAL(18,4)       NULL,
    composite_risk_score    DECIMAL(10,4)       NULL,

    -- Customer Profile at Default
    age_years               DECIMAL(5,2)        NULL,
    employment_years        DECIMAL(8,2)        NULL,
    gender                  NVARCHAR(20)        NULL,
    education_type          NVARCHAR(100)       NULL,
    income_type             NVARCHAR(100)       NULL,

    -- Bureau Indicators at Default
    active_credits_at_default   INT             NULL,
    overdue_credits_at_default  INT             NULL,

    -- Payment Indicators at Default
    late_payments_at_default    INT             NULL,
    payment_completion_ratio    DECIMAL(10,4)   NULL,

    -- Risk Segment at Default
    risk_segment            NVARCHAR(20)        NULL,

    -- Metadata
    dwh_load_date           DATETIME2           NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_fact_default_customer FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customer(customer_key),
    CONSTRAINT FK_fact_default_time FOREIGN KEY (time_key)
        REFERENCES gold.dim_time(time_key),
    CONSTRAINT FK_fact_default_region FOREIGN KEY (region_key)
        REFERENCES gold.dim_region(region_key),
    CONSTRAINT FK_fact_default_income FOREIGN KEY (income_key)
        REFERENCES gold.dim_income(income_key)
);
GO

PRINT '================================================================';
PRINT 'Gold Fact Tables Created Successfully';
PRINT '  - gold.fact_loan_application   (Core lending facts)';
PRINT '  - gold.fact_payment_behavior   (Payment aggregation)';
PRINT '  - gold.fact_credit_history     (Bureau aggregation)';
PRINT '  - gold.fact_default_events     (Default event tracking)';
PRINT '================================================================';
GO