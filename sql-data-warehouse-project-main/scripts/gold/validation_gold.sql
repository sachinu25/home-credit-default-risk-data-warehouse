USE DataWarehouse;
GO

/*
===============================================================================
Validation Script: Gold Layer
===============================================================================
Purpose:
    Validate Gold layer views for:
    - Row counts
    - Null business keys
    - Duplicate customer records
    - Risk segment distribution
    - Basic metric sanity checks
===============================================================================
*/

-- ============================================================================
-- 1. Row Count Validation
-- ============================================================================

SELECT 
    'gold.dim_customer' AS object_name,
    COUNT(*) AS row_count
FROM gold.dim_customer

UNION ALL

SELECT 
    'gold.fact_loan_application',
    COUNT(*)
FROM gold.fact_loan_application

UNION ALL

SELECT 
    'gold.fact_payment_behavior',
    COUNT(*)
FROM gold.fact_payment_behavior

UNION ALL

SELECT 
    'gold.fact_credit_history',
    COUNT(*)
FROM gold.fact_credit_history

UNION ALL

SELECT 
    'gold.report_customer_risk_summary',
    COUNT(*)
FROM gold.report_customer_risk_summary;
GO

-- ============================================================================
-- 2. Null Customer Key Checks
-- ============================================================================

SELECT 
    'dim_customer_null_customer_id' AS check_name,
    COUNT(*) AS issue_count
FROM gold.dim_customer
WHERE customer_id IS NULL

UNION ALL

SELECT 
    'fact_loan_application_null_customer_id',
    COUNT(*)
FROM gold.fact_loan_application
WHERE customer_id IS NULL

UNION ALL

SELECT 
    'report_customer_risk_summary_null_customer_id',
    COUNT(*)
FROM gold.report_customer_risk_summary
WHERE customer_id IS NULL;
GO

-- ============================================================================
-- 3. Duplicate Customer Check in dim_customer
-- ============================================================================

SELECT 
    customer_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- 4. Risk Segment Distribution
-- ============================================================================

SELECT
    risk_segment,
    COUNT(*) AS customer_count,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS percentage_share
FROM gold.report_customer_risk_summary
GROUP BY risk_segment
ORDER BY customer_count DESC;
GO

-- ============================================================================
-- 5. Default Flag Distribution
-- ============================================================================

SELECT
    default_flag,
    COUNT(*) AS application_count,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS percentage_share
FROM gold.fact_loan_application
GROUP BY default_flag
ORDER BY default_flag;
GO

-- ============================================================================
-- 6. Financial Ratio Sanity Checks
-- ============================================================================

SELECT
    COUNT(*) AS invalid_credit_income_ratio_count
FROM gold.fact_loan_application
WHERE credit_income_ratio < 0;
GO

SELECT
    COUNT(*) AS invalid_annuity_income_ratio_count
FROM gold.fact_loan_application
WHERE annuity_income_ratio < 0;
GO

SELECT
    COUNT(*) AS invalid_goods_credit_ratio_count
FROM gold.fact_loan_application
WHERE goods_credit_ratio < 0;
GO

-- ============================================================================
-- 7. Payment Behavior Sanity Checks
-- ============================================================================

SELECT
    COUNT(*) AS invalid_payment_completion_ratio_count
FROM gold.fact_payment_behavior
WHERE payment_completion_ratio < 0;
GO

SELECT
    COUNT(*) AS negative_total_installments_count
FROM gold.fact_payment_behavior
WHERE total_installments < 0;
GO

-- ============================================================================
-- 8. Bureau Credit History Sanity Checks
-- ============================================================================

SELECT
    COUNT(*) AS negative_bureau_record_count
FROM gold.fact_credit_history
WHERE total_bureau_records < 0;
GO

SELECT
    COUNT(*) AS negative_credit_sum_count
FROM gold.fact_credit_history
WHERE total_credit_sum < 0;
GO

-- ============================================================================
-- 9. Sample Report Output
-- ============================================================================

SELECT TOP 20 *
FROM gold.report_customer_risk_summary
ORDER BY customer_id;
GO