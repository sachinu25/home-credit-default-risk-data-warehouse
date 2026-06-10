USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: Load Silver Previous Application
===============================================================================
Script Purpose:
    Cleans and loads previous_application data from Bronze to Silver.

Silver Responsibilities:
    - Convert raw text into correct datatypes
    - Standardize categorical values
    - Create approval/rejection flags
    - Create useful financial ratios
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_previous_application
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @start_time DATETIME,
        @end_time DATETIME;

    BEGIN TRY

        SET @start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Silver Table: silver.previous_application';
        PRINT '================================================';

        PRINT '>> Truncating Table: silver.previous_application';
        TRUNCATE TABLE silver.previous_application;

        PRINT '>> Inserting cleaned data into silver.previous_application';

        INSERT INTO silver.previous_application (
            sk_id_prev,
            sk_id_curr,
            contract_type,
            annuity_amount,
            application_amount,
            credit_amount,
            down_payment_amount,
            goods_price,
            weekday_application_start,
            hour_application_start,
            last_application_per_contract,
            last_application_in_day,
            down_payment_rate,
            cash_loan_purpose,
            contract_status,
            days_decision,
            payment_type,
            reject_reason,
            client_type,
            goods_category,
            portfolio_type,
            product_type,
            channel_type,
            sellerplace_area,
            seller_industry,
            payment_count,
            yield_group,
            product_combination,
            credit_application_ratio,
            down_payment_credit_ratio,
            approval_flag,
            rejection_flag,
            dwh_load_date
        )
        SELECT
            TRY_CAST(NULLIF(SK_ID_PREV, '') AS INT),
            TRY_CAST(NULLIF(SK_ID_CURR, '') AS INT),

            TRIM(NULLIF(NAME_CONTRACT_TYPE, '')),

            TRY_CAST(NULLIF(AMT_ANNUITY, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_APPLICATION, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_CREDIT, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_DOWN_PAYMENT, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_GOODS_PRICE, '') AS DECIMAL(18,2)),

            TRIM(NULLIF(WEEKDAY_APPR_PROCESS_START, '')),
            TRY_CAST(NULLIF(HOUR_APPR_PROCESS_START, '') AS TINYINT),

            CASE
                WHEN FLAG_LAST_APPL_PER_CONTRACT = 'Y' THEN 'Yes'
                WHEN FLAG_LAST_APPL_PER_CONTRACT = 'N' THEN 'No'
                ELSE 'Unknown'
            END,

            TRY_CAST(NULLIF(NFLAG_LAST_APPL_IN_DAY, '') AS TINYINT),

            TRY_CAST(NULLIF(RATE_DOWN_PAYMENT, '') AS DECIMAL(18,10)),

            TRIM(NULLIF(NAME_CASH_LOAN_PURPOSE, '')),
            TRIM(NULLIF(NAME_CONTRACT_STATUS, '')),

            TRY_CAST(NULLIF(DAYS_DECISION, '') AS INT),

            TRIM(NULLIF(NAME_PAYMENT_TYPE, '')),
            TRIM(NULLIF(CODE_REJECT_REASON, '')),

            TRIM(NULLIF(NAME_CLIENT_TYPE, '')),
            TRIM(NULLIF(NAME_GOODS_CATEGORY, '')),
            TRIM(NULLIF(NAME_PORTFOLIO, '')),
            TRIM(NULLIF(NAME_PRODUCT_TYPE, '')),
            TRIM(NULLIF(CHANNEL_TYPE, '')),

            TRY_CAST(NULLIF(SELLERPLACE_AREA, '') AS INT),
            TRIM(NULLIF(NAME_SELLER_INDUSTRY, '')),

            TRY_CAST(NULLIF(CNT_PAYMENT, '') AS DECIMAL(10,2)),
            TRIM(NULLIF(NAME_YIELD_GROUP, '')),
            TRIM(NULLIF(PRODUCT_COMBINATION, '')),

            CASE
                WHEN TRY_CAST(NULLIF(AMT_APPLICATION, '') AS DECIMAL(18,2)) > 0
                    THEN TRY_CAST(NULLIF(AMT_CREDIT, '') AS DECIMAL(18,2)) /
                         TRY_CAST(NULLIF(AMT_APPLICATION, '') AS DECIMAL(18,2))
                ELSE NULL
            END AS credit_application_ratio,

            CASE
                WHEN TRY_CAST(NULLIF(AMT_CREDIT, '') AS DECIMAL(18,2)) > 0
                    THEN TRY_CAST(NULLIF(AMT_DOWN_PAYMENT, '') AS DECIMAL(18,2)) /
                         TRY_CAST(NULLIF(AMT_CREDIT, '') AS DECIMAL(18,2))
                ELSE NULL
            END AS down_payment_credit_ratio,

            CASE 
                WHEN NAME_CONTRACT_STATUS = 'Approved' THEN 1 
                ELSE 0 
            END AS approval_flag,

            CASE 
                WHEN NAME_CONTRACT_STATUS = 'Refused' THEN 1 
                ELSE 0 
            END AS rejection_flag,

            GETDATE()

        FROM bronze.previous_application;

        SET @end_time = GETDATE();

        PRINT '>> silver.previous_application loaded successfully';
        PRINT '>> Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';

    END TRY

    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR OCCURRED WHILE LOADING silver.previous_application';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '================================================';
    END CATCH
END;
GO