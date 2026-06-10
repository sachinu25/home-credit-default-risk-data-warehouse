USE DataWarehouse;
GO

/*
===============================================================================
Quality Checks: Gold Layer
===============================================================================
Purpose:
    Validate business-ready Gold layer views.

Checks:
    - row counts
    - null business keys
    - duplicate dimension keys
    - referential checks
    - risk segment distribution
    - KPI sanity checks
===============================================================================
*/

-- ============================================================================
-- 1. Row Count Validation
-- ============================================================================

SELECT 'gold.dim_customer' AS object_name, COUNT(*) AS row_count FROM gold.dim_customer
UNION ALL
SELECT 'gold.fact_loan_application', COUNT(*) FROM gold.fact_loan_application
UNION ALL
SELECT 'gold.fact_payment_behavior', COUNT(*) FROM gold.fact_payment_behavior
UNION ALL
SELECT 'gold.fact_credit_history', COUNT(*) FROM gold.fact_credit_history
UNION ALL
SELECT 'gold.report_customer_risk_summary', COUNT(*) FROM gold.report_customer_risk_summary;
GO

-- ============================================================================
-- 2. Null Customer ID Checks
-- ============================================================================

SELECT 'dim_customer_null_customer_id' AS check_name, COUNT(*) AS issue_count
FROM gold.dim_customer
WHERE customer_id IS NULL

UNION ALL

SELECT 'fact_loan_application_null_customer_id', COUNT(*)
FROM gold.fact_loan_application
WHERE customer_id IS NULL

UNION ALL

SELECT 'report_customer_risk_summary_null_customer_id', COUNT(*)
FROM gold.report_customer_risk_summary
WHERE customer_id IS NULL;
GO

-- ============================================================================
-- 3. Duplicate Customer Check in Dimension
-- ============================================================================

SELECT 
    customer_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- 4. Referential Check: fact_loan_application -> dim_customer
-- ============================================================================

SELECT 
    COUNT(*) AS orphan_loan_application_records
FROM gold.fact_loan_application f
LEFT JOIN gold.dim_customer c
    ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
GO

-- ============================================================================
-- 5. Referential Check: report_customer_risk_summary -> dim_customer
-- ============================================================================

SELECT 
    COUNT(*) AS orphan_report_records
FROM gold.report_customer_risk_summary r
LEFT JOIN gold.dim_customer c
    ON r.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
GO

-- ============================================================================
-- 6. Risk Segment Distribution
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
-- 7. Default Flag Distribution
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
-- 8. Business KPI Summary
-- ============================================================================

SELECT
    COUNT(*) AS total_customers,

    SUM(CASE WHEN default_flag = 1 THEN 1 ELSE 0 END) AS default_customers,

    CAST(
        SUM(CASE WHEN default_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    ) AS default_rate_percentage,

    AVG(income_total) AS avg_income,
    AVG(credit_amount) AS avg_credit_amount,
    AVG(annuity_amount) AS avg_annuity_amount,

    AVG(credit_income_ratio) AS avg_credit_income_ratio,
    AVG(annuity_income_ratio) AS avg_annuity_income_ratio
FROM gold.report_customer_risk_summary;
GO

-- ============================================================================
-- 9. Financial Ratio Sanity Checks
-- ============================================================================

SELECT 'invalid_credit_income_ratio' AS check_name, COUNT(*) AS issue_count
FROM gold.fact_loan_application
WHERE credit_income_ratio < 0

UNION ALL

SELECT 'invalid_annuity_income_ratio', COUNT(*)
FROM gold.fact_loan_application
WHERE annuity_income_ratio < 0

UNION ALL

SELECT 'invalid_goods_credit_ratio', COUNT(*)
FROM gold.fact_loan_application
WHERE goods_credit_ratio < 0;
GO

-- ============================================================================
-- 10. Payment Behavior Sanity Checks
-- ============================================================================

SELECT 'invalid_payment_completion_ratio' AS check_name, COUNT(*) AS issue_count
FROM gold.fact_payment_behavior
WHERE payment_completion_ratio < 0

UNION ALL

SELECT 'negative_total_installments', COUNT(*)
FROM gold.fact_payment_behavior
WHERE total_installments < 0

UNION ALL

SELECT 'negative_late_payment_count', COUNT(*)
FROM gold.fact_payment_behavior
WHERE late_payment_count < 0

UNION ALL

SELECT 'negative_underpaid_count', COUNT(*)
FROM gold.fact_payment_behavior
WHERE underpaid_count < 0;
GO

-- ============================================================================
-- 11. Bureau Credit History Sanity Checks
-- ============================================================================

SELECT 'negative_total_bureau_records' AS check_name, COUNT(*) AS issue_count
FROM gold.fact_credit_history
WHERE total_bureau_records < 0

UNION ALL

SELECT 'negative_total_credit_sum', COUNT(*)
FROM gold.fact_credit_history
WHERE total_credit_sum < 0

UNION ALL

SELECT 'negative_total_credit_debt', COUNT(*)
FROM gold.fact_credit_history
WHERE total_credit_debt < 0

UNION ALL

SELECT 'negative_overdue_credit_count', COUNT(*)
FROM gold.fact_credit_history
WHERE overdue_credit_count < 0;
GO

-- ============================================================================
-- 12. Top Risky Customer Samples
-- ============================================================================

SELECT TOP 20
    customer_id,
    gender,
    age_years,
    income_type,
    occupation_type,
    default_flag,
    credit_amount,
    income_total,
    credit_income_ratio,
    late_payment_count,
    underpaid_count,
    overdue_credit_count,
    risk_segment
FROM gold.report_customer_risk_summary
WHERE risk_segment = 'High Risk'
ORDER BY credit_income_ratio DESC;
GO