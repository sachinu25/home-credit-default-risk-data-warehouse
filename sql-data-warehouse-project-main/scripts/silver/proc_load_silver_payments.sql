USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: Load Silver Payment and Balance Tables
===============================================================================
Tables:
    - silver.installments_payments
    - silver.POS_CASH_balance
    - silver.credit_card_balance
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_payments
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @start_time DATETIME,
        @end_time DATETIME;

    BEGIN TRY

        PRINT '================================================';
        PRINT 'Loading Silver Payment and Balance Tables';
        PRINT '================================================';

        /*
        =======================================================================
        silver.installments_payments
        =======================================================================
        */

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.installments_payments';
        TRUNCATE TABLE silver.installments_payments;

        PRINT '>> Loading cleaned data into silver.installments_payments';

        INSERT INTO silver.installments_payments (
            sk_id_prev,
            sk_id_curr,
            installment_version,
            installment_number,
            days_instalment,
            days_entry_payment,
            instalment_amount,
            payment_amount,
            payment_difference,
            payment_delay_days,
            underpaid_flag,
            late_payment_flag,
            dwh_load_date
        )
        SELECT
            TRY_CAST(NULLIF(SK_ID_PREV, '') AS INT),
            TRY_CAST(NULLIF(SK_ID_CURR, '') AS INT),

            TRY_CAST(NULLIF(NUM_INSTALMENT_VERSION, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(NUM_INSTALMENT_NUMBER, '') AS INT),

            TRY_CAST(NULLIF(DAYS_INSTALMENT, '') AS INT),
            TRY_CAST(NULLIF(DAYS_ENTRY_PAYMENT, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(AMT_INSTALMENT, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_PAYMENT, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(AMT_INSTALMENT, '') AS DECIMAL(18,2))
                - TRY_CAST(NULLIF(AMT_PAYMENT, '') AS DECIMAL(18,2)) AS payment_difference,

            TRY_CAST(NULLIF(DAYS_ENTRY_PAYMENT, '') AS DECIMAL(18,2))
                - TRY_CAST(NULLIF(DAYS_INSTALMENT, '') AS DECIMAL(18,2)) AS payment_delay_days,

            CASE
                WHEN TRY_CAST(NULLIF(AMT_PAYMENT, '') AS DECIMAL(18,2))
                     < TRY_CAST(NULLIF(AMT_INSTALMENT, '') AS DECIMAL(18,2))
                    THEN 1
                ELSE 0
            END AS underpaid_flag,

            CASE
                WHEN TRY_CAST(NULLIF(DAYS_ENTRY_PAYMENT, '') AS DECIMAL(18,2))
                     > TRY_CAST(NULLIF(DAYS_INSTALMENT, '') AS DECIMAL(18,2))
                    THEN 1
                ELSE 0
            END AS late_payment_flag,

            GETDATE()

        FROM bronze.installments_payments;

        SET @end_time = GETDATE();

        PRINT '>> silver.installments_payments loaded successfully';
        PRINT '>> Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        PRINT '================================================';

        /*
        =======================================================================
        silver.POS_CASH_balance
        =======================================================================
        */

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.POS_CASH_balance';
        TRUNCATE TABLE silver.POS_CASH_balance;

        PRINT '>> Loading cleaned data into silver.POS_CASH_balance';

        INSERT INTO silver.POS_CASH_balance (
            sk_id_prev,
            sk_id_curr,
            months_balance,
            installment_count,
            future_installment_count,
            contract_status,
            days_past_due,
            days_past_due_def,
            dpd_flag,
            dwh_load_date
        )
        SELECT
            TRY_CAST(NULLIF(SK_ID_PREV, '') AS INT),
            TRY_CAST(NULLIF(SK_ID_CURR, '') AS INT),

            TRY_CAST(NULLIF(MONTHS_BALANCE, '') AS INT),

            TRY_CAST(NULLIF(CNT_INSTALMENT, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(CNT_INSTALMENT_FUTURE, '') AS DECIMAL(10,2)),

            TRIM(NULLIF(NAME_CONTRACT_STATUS, '')),

            TRY_CAST(NULLIF(SK_DPD, '') AS INT),
            TRY_CAST(NULLIF(SK_DPD_DEF, '') AS INT),

            CASE
                WHEN TRY_CAST(NULLIF(SK_DPD, '') AS INT) > 0 THEN 1
                ELSE 0
            END AS dpd_flag,

            GETDATE()

        FROM bronze.POS_CASH_balance;

        SET @end_time = GETDATE();

        PRINT '>> silver.POS_CASH_balance loaded successfully';
        PRINT '>> Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        PRINT '================================================';

        /*
        =======================================================================
        silver.credit_card_balance
        =======================================================================
        */

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.credit_card_balance';
        TRUNCATE TABLE silver.credit_card_balance;

        PRINT '>> Loading cleaned data into silver.credit_card_balance';

        INSERT INTO silver.credit_card_balance (
            sk_id_prev,
            sk_id_curr,
            months_balance,
            balance_amount,
            credit_limit_actual,
            drawings_atm_current,
            drawings_current,
            drawings_other_current,
            drawings_pos_current,
            min_regular_payment,
            payment_current,
            payment_total_current,
            receivable_principal,
            receivable_amount,
            total_receivable,
            drawings_atm_count,
            drawings_count,
            drawings_other_count,
            drawings_pos_count,
            matured_installment_count,
            contract_status,
            days_past_due,
            days_past_due_def,
            credit_utilization_ratio,
            dpd_flag,
            dwh_load_date
        )
        SELECT
            TRY_CAST(NULLIF(SK_ID_PREV, '') AS INT),
            TRY_CAST(NULLIF(SK_ID_CURR, '') AS INT),

            TRY_CAST(NULLIF(MONTHS_BALANCE, '') AS INT),

            TRY_CAST(NULLIF(AMT_BALANCE, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_CREDIT_LIMIT_ACTUAL, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(AMT_DRAWINGS_ATM_CURRENT, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_DRAWINGS_CURRENT, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_DRAWINGS_OTHER_CURRENT, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_DRAWINGS_POS_CURRENT, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(AMT_INST_MIN_REGULARITY, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_PAYMENT_CURRENT, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_PAYMENT_TOTAL_CURRENT, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(AMT_RECEIVABLE_PRINCIPAL, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_RECIVABLE, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_TOTAL_RECEIVABLE, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(CNT_DRAWINGS_ATM_CURRENT, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(CNT_DRAWINGS_CURRENT, '') AS INT),
            TRY_CAST(NULLIF(CNT_DRAWINGS_OTHER_CURRENT, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(CNT_DRAWINGS_POS_CURRENT, '') AS DECIMAL(10,2)),

            TRY_CAST(NULLIF(CNT_INSTALMENT_MATURE_CUM, '') AS DECIMAL(10,2)),

            TRIM(NULLIF(NAME_CONTRACT_STATUS, '')),

            TRY_CAST(NULLIF(SK_DPD, '') AS INT),
            TRY_CAST(NULLIF(SK_DPD_DEF, '') AS INT),

            CASE
                WHEN TRY_CAST(NULLIF(AMT_CREDIT_LIMIT_ACTUAL, '') AS DECIMAL(18,2)) > 0
                    THEN TRY_CAST(NULLIF(AMT_BALANCE, '') AS DECIMAL(18,2))
                         /
                         TRY_CAST(NULLIF(AMT_CREDIT_LIMIT_ACTUAL, '') AS DECIMAL(18,2))
                ELSE NULL
            END AS credit_utilization_ratio,

            CASE
                WHEN TRY_CAST(NULLIF(SK_DPD, '') AS INT) > 0 THEN 1
                ELSE 0
            END AS dpd_flag,

            GETDATE()

        FROM bronze.credit_card_balance;

        SET @end_time = GETDATE();

        PRINT '>> silver.credit_card_balance loaded successfully';
        PRINT '>> Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        PRINT '================================================';
        PRINT 'Silver Payment and Balance Tables Load Completed';
        PRINT '================================================';

    END TRY

    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING SILVER PAYMENTS LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '================================================';
    END CATCH
END;
GO