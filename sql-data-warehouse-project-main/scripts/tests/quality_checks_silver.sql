USE DataWarehouse;
GO

/*
===============================================================================
Quality Checks: Silver Layer
===============================================================================
Purpose:
    Validate cleaned, typed, and standardized Silver tables.

Checks:
    - row counts
    - null business keys
    - duplicate main keys
    - invalid datatypes / impossible values
    - category standardization
    - derived metric sanity
===============================================================================
*/

-- ============================================================================
-- 1. Row Count Validation
-- ============================================================================

SELECT 'silver.application_train' AS table_name, COUNT(*) AS row_count FROM silver.application_train
UNION ALL
SELECT 'silver.application_test', COUNT(*) FROM silver.application_test
UNION ALL
SELECT 'silver.bureau', COUNT(*) FROM silver.bureau
UNION ALL
SELECT 'silver.bureau_balance', COUNT(*) FROM silver.bureau_balance
UNION ALL
SELECT 'silver.previous_application', COUNT(*) FROM silver.previous_application
UNION ALL
SELECT 'silver.installments_payments', COUNT(*) FROM silver.installments_payments
UNION ALL
SELECT 'silver.POS_CASH_balance', COUNT(*) FROM silver.POS_CASH_balance
UNION ALL
SELECT 'silver.credit_card_balance', COUNT(*) FROM silver.credit_card_balance;
GO

-- ============================================================================
-- 2. Null Business Key Checks
-- ============================================================================

SELECT 'application_train_null_sk_id_curr' AS check_name, COUNT(*) AS issue_count
FROM silver.application_train
WHERE sk_id_curr IS NULL

UNION ALL

SELECT 'application_test_null_sk_id_curr', COUNT(*)
FROM silver.application_test
WHERE sk_id_curr IS NULL

UNION ALL

SELECT 'bureau_null_sk_id_curr', COUNT(*)
FROM silver.bureau
WHERE sk_id_curr IS NULL

UNION ALL

SELECT 'bureau_null_sk_id_bureau', COUNT(*)
FROM silver.bureau
WHERE sk_id_bureau IS NULL

UNION ALL

SELECT 'bureau_balance_null_sk_id_bureau', COUNT(*)
FROM silver.bureau_balance
WHERE sk_id_bureau IS NULL

UNION ALL

SELECT 'previous_application_null_sk_id_prev', COUNT(*)
FROM silver.previous_application
WHERE sk_id_prev IS NULL

UNION ALL

SELECT 'previous_application_null_sk_id_curr', COUNT(*)
FROM silver.previous_application
WHERE sk_id_curr IS NULL

UNION ALL

SELECT 'installments_null_sk_id_prev', COUNT(*)
FROM silver.installments_payments
WHERE sk_id_prev IS NULL

UNION ALL

SELECT 'installments_null_sk_id_curr', COUNT(*)
FROM silver.installments_payments
WHERE sk_id_curr IS NULL

UNION ALL

SELECT 'pos_cash_null_sk_id_prev', COUNT(*)
FROM silver.POS_CASH_balance
WHERE sk_id_prev IS NULL

UNION ALL

SELECT 'pos_cash_null_sk_id_curr', COUNT(*)
FROM silver.POS_CASH_balance
WHERE sk_id_curr IS NULL

UNION ALL

SELECT 'credit_card_null_sk_id_prev', COUNT(*)
FROM silver.credit_card_balance
WHERE sk_id_prev IS NULL

UNION ALL

SELECT 'credit_card_null_sk_id_curr', COUNT(*)
FROM silver.credit_card_balance
WHERE sk_id_curr IS NULL;
GO

-- ============================================================================
-- 3. Duplicate Key Checks
-- ============================================================================

-- application_train: 1 row per customer/application
SELECT 
    sk_id_curr,
    COUNT(*) AS duplicate_count
FROM silver.application_train
GROUP BY sk_id_curr
HAVING COUNT(*) > 1;
GO

-- application_test: 1 row per customer/application
SELECT 
    sk_id_curr,
    COUNT(*) AS duplicate_count
FROM silver.application_test
GROUP BY sk_id_curr
HAVING COUNT(*) > 1;
GO

-- bureau: 1 row per bureau record
SELECT 
    sk_id_bureau,
    COUNT(*) AS duplicate_count
FROM silver.bureau
GROUP BY sk_id_bureau
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- 4. Target Distribution
-- ============================================================================

SELECT 
    target,
    COUNT(*) AS row_count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(10,2)) AS percentage_share
FROM silver.application_train
GROUP BY target
ORDER BY target;
GO

-- ============================================================================
-- 5. Standardized Category Checks
-- ============================================================================

SELECT 
    gender,
    COUNT(*) AS row_count
FROM silver.application_train
GROUP BY gender
ORDER BY row_count DESC;
GO

SELECT 
    owns_car,
    COUNT(*) AS row_count
FROM silver.application_train
GROUP BY owns_car
ORDER BY row_count DESC;
GO

SELECT 
    owns_realty,
    COUNT(*) AS row_count
FROM silver.application_train
GROUP BY owns_realty
ORDER BY row_count DESC;
GO

-- ============================================================================
-- 6. Financial Sanity Checks
-- ============================================================================

SELECT 'negative_income_total' AS check_name, COUNT(*) AS issue_count
FROM silver.application_train
WHERE income_total < 0

UNION ALL

SELECT 'negative_credit_amount', COUNT(*)
FROM silver.application_train
WHERE credit_amount < 0

UNION ALL

SELECT 'negative_annuity_amount', COUNT(*)
FROM silver.application_train
WHERE annuity_amount < 0

UNION ALL

SELECT 'negative_goods_price', COUNT(*)
FROM silver.application_train
WHERE goods_price < 0;
GO

-- ============================================================================
-- 7. Age / Employment Sanity Checks
-- ============================================================================

SELECT 'age_less_than_18' AS check_name, COUNT(*) AS issue_count
FROM silver.application_train
WHERE age_years < 18

UNION ALL

SELECT 'age_greater_than_100', COUNT(*)
FROM silver.application_train
WHERE age_years > 100

UNION ALL

SELECT 'employment_years_negative', COUNT(*)
FROM silver.application_train
WHERE employment_years < 0

UNION ALL

SELECT 'employment_years_greater_than_70', COUNT(*)
FROM silver.application_train
WHERE employment_years > 70;
GO

-- ============================================================================
-- 8. Derived Ratio Sanity Checks
-- ============================================================================

SELECT 'negative_credit_income_ratio' AS check_name, COUNT(*) AS issue_count
FROM silver.application_train
WHERE credit_income_ratio < 0

UNION ALL

SELECT 'negative_annuity_income_ratio', COUNT(*)
FROM silver.application_train
WHERE annuity_income_ratio < 0

UNION ALL

SELECT 'negative_goods_credit_ratio', COUNT(*)
FROM silver.application_train
WHERE goods_credit_ratio < 0;
GO

-- ============================================================================
-- 9. Bureau Sanity Checks
-- ============================================================================

SELECT 'negative_credit_sum' AS check_name, COUNT(*) AS issue_count
FROM silver.bureau
WHERE credit_sum < 0

UNION ALL

SELECT 'negative_credit_debt', COUNT(*)
FROM silver.bureau
WHERE credit_sum_debt < 0

UNION ALL

SELECT 'negative_credit_overdue', COUNT(*)
FROM silver.bureau
WHERE credit_sum_overdue < 0

UNION ALL

SELECT 'invalid_overdue_flag', COUNT(*)
FROM silver.bureau
WHERE overdue_flag NOT IN (0,1);
GO

-- ============================================================================
-- 10. Payment Behavior Checks
-- ============================================================================

SELECT 'invalid_underpaid_flag' AS check_name, COUNT(*) AS issue_count
FROM silver.installments_payments
WHERE underpaid_flag NOT IN (0,1)

UNION ALL

SELECT 'invalid_late_payment_flag', COUNT(*)
FROM silver.installments_payments
WHERE late_payment_flag NOT IN (0,1);
GO

-- ============================================================================
-- 11. POS / Credit Card Flag Checks
-- ============================================================================

SELECT 'invalid_pos_dpd_flag' AS check_name, COUNT(*) AS issue_count
FROM silver.POS_CASH_balance
WHERE dpd_flag NOT IN (0,1)

UNION ALL

SELECT 'invalid_credit_card_dpd_flag', COUNT(*)
FROM silver.credit_card_balance
WHERE dpd_flag NOT IN (0,1);
GO

-- ============================================================================
-- 12. Sample Cleaned Records
-- ============================================================================

SELECT TOP 10 * FROM silver.application_train;
SELECT TOP 10 * FROM silver.bureau;
SELECT TOP 10 * FROM silver.installments_payments;
GO