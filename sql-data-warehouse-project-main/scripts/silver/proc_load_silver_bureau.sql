USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: Load Silver Bureau Tables
===============================================================================
Script Purpose:
    Cleans and loads bureau-related data from Bronze to Silver layer.

Tables:
    - silver.bureau
    - silver.bureau_balance
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_bureau
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE 
        @start_time DATETIME,
        @end_time DATETIME;

    BEGIN TRY

        PRINT '================================================';
        PRINT 'Loading Silver Bureau Tables';
        PRINT '================================================';

        /*
        =======================================================================
        silver.bureau
        =======================================================================
        */

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.bureau';

        TRUNCATE TABLE silver.bureau;

        PRINT '>> Loading cleaned data into silver.bureau';

        INSERT INTO silver.bureau (

            sk_id_curr,
            sk_id_bureau,

            credit_active,
            credit_currency,

            days_credit,
            credit_day_overdue,

            days_credit_enddate,
            days_enddate_fact,

            credit_max_overdue,

            credit_prolong_count,

            credit_sum,
            credit_sum_debt,
            credit_sum_limit,
            credit_sum_overdue,

            credit_type,

            days_credit_update,

            annuity_amount,

            credit_debt_ratio,
            overdue_flag,

            dwh_load_date
        )

        SELECT

            TRY_CAST(NULLIF(SK_ID_CURR, '') AS INT),

            TRY_CAST(NULLIF(SK_ID_BUREAU, '') AS INT),

            TRIM(NULLIF(CREDIT_ACTIVE, '')),

            TRIM(NULLIF(CREDIT_CURRENCY, '')),

            TRY_CAST(NULLIF(DAYS_CREDIT, '') AS INT),

            TRY_CAST(NULLIF(CREDIT_DAY_OVERDUE, '') AS INT),

            TRY_CAST(NULLIF(DAYS_CREDIT_ENDDATE, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(DAYS_ENDDATE_FACT, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(AMT_CREDIT_MAX_OVERDUE, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(CNT_CREDIT_PROLONG, '') AS INT),

            TRY_CAST(NULLIF(AMT_CREDIT_SUM, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(AMT_CREDIT_SUM_DEBT, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(AMT_CREDIT_SUM_LIMIT, '') AS DECIMAL(18,2)),

            TRY_CAST(NULLIF(AMT_CREDIT_SUM_OVERDUE, '') AS DECIMAL(18,2)),

            TRIM(NULLIF(CREDIT_TYPE, '')),

            TRY_CAST(NULLIF(DAYS_CREDIT_UPDATE, '') AS INT),

            TRY_CAST(NULLIF(AMT_ANNUITY, '') AS DECIMAL(18,2)),

            CASE
                WHEN TRY_CAST(NULLIF(AMT_CREDIT_SUM, '') AS DECIMAL(18,2)) > 0
                    THEN TRY_CAST(NULLIF(AMT_CREDIT_SUM_DEBT, '') AS DECIMAL(18,2))
                         /
                         TRY_CAST(NULLIF(AMT_CREDIT_SUM, '') AS DECIMAL(18,2))
                ELSE NULL
            END AS credit_debt_ratio,

            CASE
                WHEN TRY_CAST(NULLIF(CREDIT_DAY_OVERDUE, '') AS INT) > 0
                    THEN 1
                ELSE 0
            END AS overdue_flag,

            GETDATE()

        FROM bronze.bureau;

        SET @end_time = GETDATE();

        PRINT '>> silver.bureau loaded successfully';
        PRINT '>> Duration: ' +
              CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) +
              ' seconds';

        PRINT '================================================';

        /*
        =======================================================================
        silver.bureau_balance
        =======================================================================
        */

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.bureau_balance';

        TRUNCATE TABLE silver.bureau_balance;

        PRINT '>> Loading cleaned data into silver.bureau_balance';

        INSERT INTO silver.bureau_balance (

            sk_id_bureau,

            months_balance,

            status,

            status_group,

            dwh_load_date
        )

        SELECT

            TRY_CAST(NULLIF(SK_ID_BUREAU, '') AS INT),

            TRY_CAST(NULLIF(MONTHS_BALANCE, '') AS INT),

            TRIM(NULLIF(STATUS, '')),

            CASE

                WHEN STATUS IN ('0','1')
                    THEN 'Low Risk'

                WHEN STATUS IN ('2','3')
                    THEN 'Medium Risk'

                WHEN STATUS IN ('4','5')
                    THEN 'High Risk'

                WHEN STATUS = 'C'
                    THEN 'Closed'

                WHEN STATUS = 'X'
                    THEN 'No Loan'

                ELSE 'Unknown'

            END AS status_group,

            GETDATE()

        FROM bronze.bureau_balance;

        SET @end_time = GETDATE();

        PRINT '>> silver.bureau_balance loaded successfully';
        PRINT '>> Duration: ' +
              CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) +
              ' seconds';

        PRINT '================================================';
        PRINT 'Silver Bureau Load Completed';
        PRINT '================================================';

    END TRY

    BEGIN CATCH

        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING SILVER BUREAU LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '================================================';

    END CATCH

END;
GO