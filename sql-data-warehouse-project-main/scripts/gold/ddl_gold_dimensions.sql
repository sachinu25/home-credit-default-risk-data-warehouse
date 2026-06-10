USE DataWarehouse;
GO

/*
===============================================================================
DDL Script: Gold Dimensions — Enterprise Star Schema
===============================================================================
Purpose:
    Creates production-grade dimension TABLES (not views) for the Gold layer
    star schema. Includes SCD Type 2 for dim_customer, a calendar dimension,
    and conformed dimensions for credit, region, and income.

Design Principles:
    ✓ Surrogate keys via IDENTITY (stable, never change)
    ✓ SCD Type 2 for dim_customer (historical tracking)
    ✓ Conformed dimensions for cross-fact analysis
    ✓ Kimball methodology throughout
    ✓ Proper primary key constraints

Dimensions:
    1. gold.dim_customer    — SCD Type 2 customer master
    2. gold.dim_time        — Calendar/date dimension
    3. gold.dim_credit      — Credit type dimension
    4. gold.dim_region      — Region rating dimension
    5. gold.dim_income      — Income band dimension

Author:     Anumodit Shukla
Created:    2025
Modified:   2026 — Enterprise star schema redesign
===============================================================================
*/

-- ============================================================================
-- Ensure Gold Schema Exists
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END;
GO

-- ============================================================================
-- Drop Existing Objects (Views from original, Tables from upgrade)
-- ============================================================================

DROP VIEW  IF EXISTS gold.dim_customer;
DROP TABLE IF EXISTS gold.dim_customer;
DROP TABLE IF EXISTS gold.dim_time;
DROP TABLE IF EXISTS gold.dim_credit;
DROP TABLE IF EXISTS gold.dim_region;
DROP TABLE IF EXISTS gold.dim_income;
GO

/*
===============================================================================
Dimension 1: dim_customer — SCD Type 2
===============================================================================
Purpose:
    Customer master dimension with full historical tracking.
    Every change to a customer's attributes creates a new version,
    preserving the old version with an end_date.

Grain:
    1 row = 1 version of 1 customer

SCD Type 2 Columns:
    - effective_date  : When this version became active
    - end_date        : When this version was superseded (NULL = current)
    - is_current      : Flag for current active version

Business Usage:
    - Customer segmentation and profiling
    - Historical risk tracking
    - Regulatory audit trail (BCBS 239 compliance)
    - Power BI dimension slicers
===============================================================================
*/

CREATE TABLE gold.dim_customer (

    -- Surrogate Key (stable, system-generated)
    customer_key            INT IDENTITY(1,1)   PRIMARY KEY,

    -- Business Key
    customer_id             INT                 NOT NULL,

    -- Demographics
    gender                  NVARCHAR(20)        NULL,
    age_years               DECIMAL(5,2)        NULL,

    -- Age Band (derived for analysis)
    age_band                NVARCHAR(20)        NULL,       -- '18-25', '26-35', etc.

    -- Family Information
    family_status           NVARCHAR(100)       NULL,
    children_count          INT                 NULL,
    family_members_count    DECIMAL(10,2)       NULL,

    -- Education & Profession
    education_type          NVARCHAR(100)       NULL,
    occupation_type         NVARCHAR(100)       NULL,
    income_type             NVARCHAR(100)       NULL,
    organization_type       NVARCHAR(100)       NULL,

    -- Housing & Assets
    housing_type            NVARCHAR(100)       NULL,
    owns_car                NVARCHAR(10)        NULL,
    owns_realty             NVARCHAR(10)        NULL,

    -- Regional Information
    region_rating_client    TINYINT             NULL,
    region_rating_w_city    TINYINT             NULL,

    -- External Risk Scores
    ext_source_1            DECIMAL(18,10)      NULL,
    ext_source_2            DECIMAL(18,10)      NULL,
    ext_source_3            DECIMAL(18,10)      NULL,

    -- Composite Risk Score (weighted average of ext sources)
    composite_risk_score    DECIMAL(10,4)       NULL,

    -- SCD Type 2 Columns
    effective_date          DATE                NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    end_date                DATE                NULL,       -- NULL = currently active
    is_current              BIT                 NOT NULL DEFAULT 1,

    -- Metadata
    dwh_created_date        DATETIME2           NOT NULL DEFAULT SYSDATETIME(),
    dwh_modified_date       DATETIME2           NOT NULL DEFAULT SYSDATETIME()
);
GO

-- Index for business key lookups
CREATE NONCLUSTERED INDEX IX_dim_customer_business_key 
ON gold.dim_customer (customer_id, is_current)
INCLUDE (gender, age_band, income_type);
GO

/*
===============================================================================
Dimension 2: dim_time — Calendar Dimension
===============================================================================
Purpose:
    Standard enterprise calendar dimension for time-based analysis.
    Pre-populated with dates for the data range.

Grain:
    1 row = 1 calendar date

Business Usage:
    - Monthly/quarterly trend analysis
    - Seasonal pattern detection
    - Fiscal period reporting
    - Day-of-week analysis
===============================================================================
*/

CREATE TABLE gold.dim_time (

    time_key                INT                 PRIMARY KEY,   -- YYYYMMDD format
    full_date               DATE                NOT NULL,
    
    -- Day-level attributes
    day_of_week             TINYINT             NOT NULL,
    day_name                NVARCHAR(10)        NOT NULL,
    day_of_month            TINYINT             NOT NULL,
    day_of_year             SMALLINT            NOT NULL,
    is_weekend              BIT                 NOT NULL,
    is_weekday              BIT                 NOT NULL,

    -- Week-level attributes
    week_of_year            TINYINT             NOT NULL,
    iso_week                TINYINT             NOT NULL,

    -- Month-level attributes
    month_number            TINYINT             NOT NULL,
    month_name              NVARCHAR(10)        NOT NULL,
    month_short             NVARCHAR(3)         NOT NULL,

    -- Quarter-level attributes
    quarter_number          TINYINT             NOT NULL,
    quarter_name            NVARCHAR(2)         NOT NULL,     -- Q1, Q2, Q3, Q4

    -- Year-level attributes
    calendar_year           SMALLINT            NOT NULL,
    year_month              NVARCHAR(7)         NOT NULL,     -- 2024-01
    year_quarter            NVARCHAR(7)         NOT NULL,     -- 2024-Q1

    -- Fiscal calendar (July fiscal year start)
    fiscal_year             SMALLINT            NOT NULL,
    fiscal_quarter          TINYINT             NOT NULL,
    fiscal_quarter_name     NVARCHAR(7)         NOT NULL,

    -- Relative flags
    is_current_month        BIT                 NOT NULL DEFAULT 0,
    is_current_quarter      BIT                 NOT NULL DEFAULT 0,
    is_current_year         BIT                 NOT NULL DEFAULT 0
);
GO

/*
===============================================================================
Dimension 3: dim_credit — Credit Type Dimension
===============================================================================
Purpose:
    Conformed dimension for credit product types from bureau data.
    Includes risk weighting for portfolio analysis.

Grain:
    1 row = 1 credit type

Business Usage:
    - Product risk comparison
    - Portfolio concentration analysis
    - Credit type mix reporting
===============================================================================
*/

CREATE TABLE gold.dim_credit (

    credit_type_key         INT IDENTITY(1,1)   PRIMARY KEY,
    credit_type             NVARCHAR(100)       NOT NULL,
    credit_category         NVARCHAR(50)        NOT NULL,     -- Revolving, Installment, Mortgage, etc.
    risk_weight             DECIMAL(5,2)        NOT NULL DEFAULT 1.00,  -- Basel-style risk weight
    description             NVARCHAR(500)       NULL,

    CONSTRAINT UQ_dim_credit_type UNIQUE (credit_type)
);
GO

/*
===============================================================================
Dimension 4: dim_region — Region Dimension
===============================================================================
Purpose:
    Regional rating dimension derived from application data.
    Enables geographic risk analysis.

Grain:
    1 row = 1 region rating combination

Business Usage:
    - Geographic risk distribution
    - Regional portfolio analysis
    - City vs. region rating comparison
===============================================================================
*/

CREATE TABLE gold.dim_region (

    region_key              INT IDENTITY(1,1)   PRIMARY KEY,
    region_rating           TINYINT             NOT NULL,
    city_rating             TINYINT             NOT NULL,
    region_tier             NVARCHAR(20)        NOT NULL,     -- 'Tier 1', 'Tier 2', 'Tier 3'
    risk_classification     NVARCHAR(20)        NOT NULL,     -- 'Low', 'Medium', 'High'
    description             NVARCHAR(255)       NULL,

    CONSTRAINT UQ_dim_region_rating UNIQUE (region_rating, city_rating)
);
GO

/*
===============================================================================
Dimension 5: dim_income — Income Band Dimension
===============================================================================
Purpose:
    Income band dimension for customer wealth segmentation.
    Pre-defined bands for consistent analysis across reports.

Grain:
    1 row = 1 income band

Business Usage:
    - Wealth-based customer segmentation
    - Default rate by income analysis
    - Affordability assessment
===============================================================================
*/

CREATE TABLE gold.dim_income (

    income_key              INT IDENTITY(1,1)   PRIMARY KEY,
    income_band             NVARCHAR(50)        NOT NULL,
    income_min              DECIMAL(18,2)       NOT NULL,
    income_max              DECIMAL(18,2)       NOT NULL,
    income_percentile       NVARCHAR(20)        NULL,         -- 'Bottom 20%', 'Top 10%', etc.
    band_order              INT                 NOT NULL,     -- For sorting

    CONSTRAINT UQ_dim_income_band UNIQUE (income_band)
);
GO

PRINT '================================================================';
PRINT 'Gold Dimension Tables Created Successfully';
PRINT '  - gold.dim_customer    (SCD Type 2)';
PRINT '  - gold.dim_time        (Calendar)';
PRINT '  - gold.dim_credit      (Credit Type)';
PRINT '  - gold.dim_region      (Region Rating)';
PRINT '  - gold.dim_income      (Income Band)';
PRINT '================================================================';
GO