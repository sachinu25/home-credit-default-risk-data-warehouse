USE DataWarehouse;
GO

/*
===============================================================================
Quality Checks: Bronze Layer
===============================================================================
Purpose:
    Validate raw ingestion completeness and basic structural health.

Layer Principle:
    Bronze = raw data as-is.
    We do not validate business correctness here.
    We mainly check:
        - row counts
        - null/blank source keys
        - duplicate raw business keys
        - sample inspection
===============================================================================
*/

-- ============================================================================
-- 1. Row Count Check
-- ============================================================================

SELECT 'bronze.application_train' AS table_name, COUNT(*) AS row_count FROM bronze.application_train
UNION ALL
SELECT 'bronze.application_test', COUNT(*) FROM bronze.application_test
UNION ALL
SELECT 'bronze.bureau', COUNT(*) FROM bronze.bureau
UNION ALL
SELECT 'bronze.bureau_balance', COUNT(*) FROM bronze.bureau_balance
UNION ALL
SELECT 'bronze.previous_application', COUNT(*) FROM bronze.previous_application
UNION ALL
SELECT 'bronze.installments_payments', COUNT(*) FROM bronze.installments_payments
UNION ALL
SELECT 'bronze.POS_CASH_balance', COUNT(*) FROM bronze.POS_CASH_balance
UNION ALL
SELECT 'bronze.credit_card_balance', COUNT(*) FROM bronze.credit_card_balance
UNION ALL
SELECT 'bronze.sample_submission', COUNT(*) FROM bronze.sample_submission
UNION ALL
SELECT 'bronze.HomeCredit_columns_description', COUNT(*) FROM bronze.HomeCredit_columns_description;
GO

-- ============================================================================
-- 2. Main Key Blank / NULL Checks
-- ============================================================================

SELECT 'application_train_blank_sk_id_curr' AS check_name, COUNT(*) AS issue_count
FROM bronze.application_train
WHERE SK_ID_CURR IS NULL OR TRIM(SK_ID_CURR) = ''

UNION ALL

SELECT 'application_test_blank_sk_id_curr', COUNT(*)
FROM bronze.application_test
WHERE SK_ID_CURR IS NULL OR TRIM(SK_ID_CURR) = ''

UNION ALL

SELECT 'bureau_blank_sk_id_curr', COUNT(*)
FROM bronze.bureau
WHERE SK_ID_CURR IS NULL OR TRIM(SK_ID_CURR) = ''

UNION ALL

SELECT 'bureau_blank_sk_id_bureau', COUNT(*)
FROM bronze.bureau
WHERE SK_ID_BUREAU IS NULL OR TRIM(SK_ID_BUREAU) = ''

UNION ALL

SELECT 'bureau_balance_blank_sk_id_bureau', COUNT(*)
FROM bronze.bureau_balance
WHERE SK_ID_BUREAU IS NULL OR TRIM(SK_ID_BUREAU) = ''

UNION ALL

SELECT 'previous_application_blank_sk_id_prev', COUNT(*)
FROM bronze.previous_application
WHERE SK_ID_PREV IS NULL OR TRIM(SK_ID_PREV) = ''

UNION ALL

SELECT 'previous_application_blank_sk_id_curr', COUNT(*)
FROM bronze.previous_application
WHERE SK_ID_CURR IS NULL OR TRIM(SK_ID_CURR) = ''

UNION ALL

SELECT 'installments_blank_sk_id_prev', COUNT(*)
FROM bronze.installments_payments
WHERE SK_ID_PREV IS NULL OR TRIM(SK_ID_PREV) = ''

UNION ALL

SELECT 'installments_blank_sk_id_curr', COUNT(*)
FROM bronze.installments_payments
WHERE SK_ID_CURR IS NULL OR TRIM(SK_ID_CURR) = ''

UNION ALL

SELECT 'pos_cash_blank_sk_id_prev', COUNT(*)
FROM bronze.POS_CASH_balance
WHERE SK_ID_PREV IS NULL OR TRIM(SK_ID_PREV) = ''

UNION ALL

SELECT 'pos_cash_blank_sk_id_curr', COUNT(*)
FROM bronze.POS_CASH_balance
WHERE SK_ID_CURR IS NULL OR TRIM(SK_ID_CURR) = ''

UNION ALL

SELECT 'credit_card_blank_sk_id_prev', COUNT(*)
FROM bronze.credit_card_balance
WHERE SK_ID_PREV IS NULL OR TRIM(SK_ID_PREV) = ''

UNION ALL

SELECT 'credit_card_blank_sk_id_curr', COUNT(*)
FROM bronze.credit_card_balance
WHERE SK_ID_CURR IS NULL OR TRIM(SK_ID_CURR) = '';
GO

-- ============================================================================
-- 3. Duplicate Checks for Main Unique-Like Keys
-- ============================================================================

-- application_train should generally have 1 row per SK_ID_CURR
SELECT 
    SK_ID_CURR,
    COUNT(*) AS duplicate_count
FROM bronze.application_train
GROUP BY SK_ID_CURR
HAVING COUNT(*) > 1;
GO

-- application_test should generally have 1 row per SK_ID_CURR
SELECT 
    SK_ID_CURR,
    COUNT(*) AS duplicate_count
FROM bronze.application_test
GROUP BY SK_ID_CURR
HAVING COUNT(*) > 1;
GO

-- bureau SK_ID_BUREAU should generally be unique
SELECT 
    SK_ID_BUREAU,
    COUNT(*) AS duplicate_count
FROM bronze.bureau
GROUP BY SK_ID_BUREAU
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- 4. Raw Target Value Check
-- ============================================================================

SELECT 
    TARGET,
    COUNT(*) AS row_count
FROM bronze.application_train
GROUP BY TARGET
ORDER BY TARGET;
GO

-- ============================================================================
-- 5. Sample Raw Records
-- ============================================================================

SELECT TOP 10 * FROM bronze.application_train;
SELECT TOP 10 * FROM bronze.bureau;
SELECT TOP 10 * FROM bronze.previous_application;
GO