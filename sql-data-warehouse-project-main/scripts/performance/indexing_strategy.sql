USE DataWarehouse;
GO

/*
===============================================================================
Performance Optimization — Indexing Strategy
===============================================================================
Purpose:
    Practical index definitions for the Gold layer star schema.
    Optimized for the most common analytical query patterns.

Index Types Used:
    ✓ Clustered indexes (on surrogate keys — via PK constraint)
    ✓ Non-clustered indexes (on foreign keys and filter columns)
    ✓ Covering indexes (include columns to avoid key lookups)

Note:
    Clustered indexes are already created by PRIMARY KEY constraints
    on dimension and fact tables. These scripts add supporting
    non-clustered indexes for query performance.

Author:     Anumodit Shukla
===============================================================================
*/

-- ============================================================================
-- FACT TABLE INDEXES
-- ============================================================================

-- fact_loan_application: Foreign key indexes for dimension joins
CREATE NONCLUSTERED INDEX IX_fact_loan_customer_key
ON gold.fact_loan_application (customer_key)
INCLUDE (default_flag, credit_amount, income_total, risk_segment);
GO

CREATE NONCLUSTERED INDEX IX_fact_loan_region_key
ON gold.fact_loan_application (region_key);
GO

CREATE NONCLUSTERED INDEX IX_fact_loan_income_key
ON gold.fact_loan_application (income_key);
GO

CREATE NONCLUSTERED INDEX IX_fact_loan_time_key
ON gold.fact_loan_application (time_key);
GO

-- Most common filter: default_flag
CREATE NONCLUSTERED INDEX IX_fact_loan_default_flag
ON gold.fact_loan_application (default_flag)
INCLUDE (customer_key, credit_amount, risk_segment);
GO

-- Risk segment filtering
CREATE NONCLUSTERED INDEX IX_fact_loan_risk_segment
ON gold.fact_loan_application (risk_segment)
INCLUDE (customer_key, credit_amount, default_flag);
GO

-- fact_payment_behavior: FK index
CREATE NONCLUSTERED INDEX IX_fact_payment_customer_key
ON gold.fact_payment_behavior (customer_key)
INCLUDE (late_payment_count, payment_completion_ratio, payment_health_score);
GO

-- fact_credit_history: FK index
CREATE NONCLUSTERED INDEX IX_fact_credit_customer_key
ON gold.fact_credit_history (customer_key)
INCLUDE (overdue_credit_count, credit_utilization, credit_health_score);
GO

-- fact_default_events: FK indexes
CREATE NONCLUSTERED INDEX IX_fact_default_customer_key
ON gold.fact_default_events (customer_key);
GO

CREATE NONCLUSTERED INDEX IX_fact_default_region_key
ON gold.fact_default_events (region_key);
GO

-- ============================================================================
-- DIMENSION TABLE INDEXES
-- ============================================================================

-- dim_customer: Most common lookups
CREATE NONCLUSTERED INDEX IX_dim_customer_age_band
ON gold.dim_customer (age_band, is_current)
INCLUDE (gender, income_type, education_type);
GO

CREATE NONCLUSTERED INDEX IX_dim_customer_income_type
ON gold.dim_customer (income_type, is_current);
GO

-- dim_time: Common date filters
CREATE NONCLUSTERED INDEX IX_dim_time_year_month
ON gold.dim_time (calendar_year, month_number);
GO

CREATE NONCLUSTERED INDEX IX_dim_time_quarter
ON gold.dim_time (calendar_year, quarter_number);
GO

-- ============================================================================
-- SILVER LAYER INDEXES (for ETL performance)
-- ============================================================================

-- Frequently joined column in Silver → Gold loads
CREATE NONCLUSTERED INDEX IX_silver_app_train_sk_id
ON silver.application_train (sk_id_curr);
GO

CREATE NONCLUSTERED INDEX IX_silver_bureau_sk_id
ON silver.bureau (sk_id_curr);
GO

CREATE NONCLUSTERED INDEX IX_silver_installments_sk_id
ON silver.installments_payments (sk_id_curr);
GO

CREATE NONCLUSTERED INDEX IX_silver_credit_card_sk_id
ON silver.credit_card_balance (sk_id_curr);
GO

PRINT '================================================================';
PRINT 'Indexing Strategy Applied Successfully';
PRINT '  Fact table indexes     : 10';
PRINT '  Dimension indexes      : 4';
PRINT '  Silver layer indexes   : 4';
PRINT '  Total indexes created  : 18';
PRINT '================================================================';
GO
