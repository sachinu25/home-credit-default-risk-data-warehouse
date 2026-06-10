USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: Load Bronze Layer (Enterprise Edition)
===============================================================================
Purpose:
    Loads raw CSV data into Bronze layer with full audit logging,
    per-table error handling, row count tracking, and batch correlation.

Loading Strategy:
    CSV File → Temp Staging Table (#stage) → Bronze Table (+ dwh_load_date)

Enterprise Features:
    ✓ Batch ID tracking for lineage
    ✓ Per-table TRY/CATCH with error logging to audit tables
    ✓ Row count capture and validation
    ✓ ETL run logging (start/end/duration)
    ✓ Consolidated status reporting

Author:     Anumodit Shukla
Modified:   2026 — Enterprise upgrade with audit framework
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE 
        @batch_id       UNIQUEIDENTIFIER = NEWID(),
        @run_id         INT,
        @row_count      INT,
        @start_time     DATETIME2,
        @table_count    INT = 0,
        @error_count    INT = 0;

    PRINT '================================================================';
    PRINT 'BRONZE LAYER LOAD — Batch: ' + CAST(@batch_id AS NVARCHAR(50));
    PRINT 'Started: ' + CONVERT(NVARCHAR, SYSDATETIME(), 120);
    PRINT '================================================================';

    -- ==================================================================
    -- 1. application_train
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'bronze.load_bronze',
            @layer = 'bronze',
            @table_name = 'application_train',
            @batch_id = @batch_id,
            @run_id = @run_id OUTPUT;

        SET @start_time = SYSDATETIME();
        PRINT '>> Loading: bronze.application_train';

        TRUNCATE TABLE bronze.application_train;

        CREATE TABLE #application_train_stage (
            SK_ID_CURR NVARCHAR(255), TARGET NVARCHAR(255),
            NAME_CONTRACT_TYPE NVARCHAR(255), CODE_GENDER NVARCHAR(255),
            FLAG_OWN_CAR NVARCHAR(255), FLAG_OWN_REALTY NVARCHAR(255),
            CNT_CHILDREN NVARCHAR(255),
            AMT_INCOME_TOTAL NVARCHAR(255), AMT_CREDIT NVARCHAR(255),
            AMT_ANNUITY NVARCHAR(255), AMT_GOODS_PRICE NVARCHAR(255),
            NAME_TYPE_SUITE NVARCHAR(255), NAME_INCOME_TYPE NVARCHAR(255),
            NAME_EDUCATION_TYPE NVARCHAR(255), NAME_FAMILY_STATUS NVARCHAR(255),
            NAME_HOUSING_TYPE NVARCHAR(255),
            REGION_POPULATION_RELATIVE NVARCHAR(255),
            DAYS_BIRTH NVARCHAR(255), DAYS_EMPLOYED NVARCHAR(255),
            DAYS_REGISTRATION NVARCHAR(255), DAYS_ID_PUBLISH NVARCHAR(255),
            OWN_CAR_AGE NVARCHAR(255),
            FLAG_MOBIL NVARCHAR(255), FLAG_EMP_PHONE NVARCHAR(255),
            FLAG_WORK_PHONE NVARCHAR(255), FLAG_CONT_MOBILE NVARCHAR(255),
            FLAG_PHONE NVARCHAR(255), FLAG_EMAIL NVARCHAR(255),
            OCCUPATION_TYPE NVARCHAR(255), CNT_FAM_MEMBERS NVARCHAR(255),
            REGION_RATING_CLIENT NVARCHAR(255), REGION_RATING_CLIENT_W_CITY NVARCHAR(255),
            WEEKDAY_APPR_PROCESS_START NVARCHAR(255), HOUR_APPR_PROCESS_START NVARCHAR(255),
            REG_REGION_NOT_LIVE_REGION NVARCHAR(255), REG_REGION_NOT_WORK_REGION NVARCHAR(255),
            LIVE_REGION_NOT_WORK_REGION NVARCHAR(255),
            REG_CITY_NOT_LIVE_CITY NVARCHAR(255), REG_CITY_NOT_WORK_CITY NVARCHAR(255),
            LIVE_CITY_NOT_WORK_CITY NVARCHAR(255),
            ORGANIZATION_TYPE NVARCHAR(255),
            EXT_SOURCE_1 NVARCHAR(255), EXT_SOURCE_2 NVARCHAR(255), EXT_SOURCE_3 NVARCHAR(255),
            APARTMENTS_AVG NVARCHAR(255), BASEMENTAREA_AVG NVARCHAR(255),
            YEARS_BEGINEXPLUATATION_AVG NVARCHAR(255), YEARS_BUILD_AVG NVARCHAR(255),
            COMMONAREA_AVG NVARCHAR(255), ELEVATORS_AVG NVARCHAR(255),
            ENTRANCES_AVG NVARCHAR(255), FLOORSMAX_AVG NVARCHAR(255),
            FLOORSMIN_AVG NVARCHAR(255), LANDAREA_AVG NVARCHAR(255),
            LIVINGAPARTMENTS_AVG NVARCHAR(255), LIVINGAREA_AVG NVARCHAR(255),
            NONLIVINGAPARTMENTS_AVG NVARCHAR(255), NONLIVINGAREA_AVG NVARCHAR(255),
            APARTMENTS_MODE NVARCHAR(255), BASEMENTAREA_MODE NVARCHAR(255),
            YEARS_BEGINEXPLUATATION_MODE NVARCHAR(255), YEARS_BUILD_MODE NVARCHAR(255),
            COMMONAREA_MODE NVARCHAR(255), ELEVATORS_MODE NVARCHAR(255),
            ENTRANCES_MODE NVARCHAR(255), FLOORSMAX_MODE NVARCHAR(255),
            FLOORSMIN_MODE NVARCHAR(255), LANDAREA_MODE NVARCHAR(255),
            LIVINGAPARTMENTS_MODE NVARCHAR(255), LIVINGAREA_MODE NVARCHAR(255),
            NONLIVINGAPARTMENTS_MODE NVARCHAR(255), NONLIVINGAREA_MODE NVARCHAR(255),
            APARTMENTS_MEDI NVARCHAR(255), BASEMENTAREA_MEDI NVARCHAR(255),
            YEARS_BEGINEXPLUATATION_MEDI NVARCHAR(255), YEARS_BUILD_MEDI NVARCHAR(255),
            COMMONAREA_MEDI NVARCHAR(255), ELEVATORS_MEDI NVARCHAR(255),
            ENTRANCES_MEDI NVARCHAR(255), FLOORSMAX_MEDI NVARCHAR(255),
            FLOORSMIN_MEDI NVARCHAR(255), LANDAREA_MEDI NVARCHAR(255),
            LIVINGAPARTMENTS_MEDI NVARCHAR(255), LIVINGAREA_MEDI NVARCHAR(255),
            NONLIVINGAPARTMENTS_MEDI NVARCHAR(255), NONLIVINGAREA_MEDI NVARCHAR(255),
            FONDKAPREMONT_MODE NVARCHAR(255), HOUSETYPE_MODE NVARCHAR(255),
            TOTALAREA_MODE NVARCHAR(255),
            WALLSMATERIAL_MODE NVARCHAR(255), EMERGENCYSTATE_MODE NVARCHAR(255),
            OBS_30_CNT_SOCIAL_CIRCLE NVARCHAR(255), DEF_30_CNT_SOCIAL_CIRCLE NVARCHAR(255),
            OBS_60_CNT_SOCIAL_CIRCLE NVARCHAR(255), DEF_60_CNT_SOCIAL_CIRCLE NVARCHAR(255),
            DAYS_LAST_PHONE_CHANGE NVARCHAR(255),
            FLAG_DOCUMENT_2 NVARCHAR(255), FLAG_DOCUMENT_3 NVARCHAR(255),
            FLAG_DOCUMENT_4 NVARCHAR(255), FLAG_DOCUMENT_5 NVARCHAR(255),
            FLAG_DOCUMENT_6 NVARCHAR(255), FLAG_DOCUMENT_7 NVARCHAR(255),
            FLAG_DOCUMENT_8 NVARCHAR(255), FLAG_DOCUMENT_9 NVARCHAR(255),
            FLAG_DOCUMENT_10 NVARCHAR(255), FLAG_DOCUMENT_11 NVARCHAR(255),
            FLAG_DOCUMENT_12 NVARCHAR(255), FLAG_DOCUMENT_13 NVARCHAR(255),
            FLAG_DOCUMENT_14 NVARCHAR(255), FLAG_DOCUMENT_15 NVARCHAR(255),
            FLAG_DOCUMENT_16 NVARCHAR(255), FLAG_DOCUMENT_17 NVARCHAR(255),
            FLAG_DOCUMENT_18 NVARCHAR(255), FLAG_DOCUMENT_19 NVARCHAR(255),
            FLAG_DOCUMENT_20 NVARCHAR(255), FLAG_DOCUMENT_21 NVARCHAR(255),
            AMT_REQ_CREDIT_BUREAU_HOUR NVARCHAR(255), AMT_REQ_CREDIT_BUREAU_DAY NVARCHAR(255),
            AMT_REQ_CREDIT_BUREAU_WEEK NVARCHAR(255), AMT_REQ_CREDIT_BUREAU_MON NVARCHAR(255),
            AMT_REQ_CREDIT_BUREAU_QRT NVARCHAR(255), AMT_REQ_CREDIT_BUREAU_YEAR NVARCHAR(255)
        );

        BULK INSERT #application_train_stage
        FROM 'C:\home-credit-default-risk\application_train.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            CODEPAGE = '65001',
            TABLOCK
        );

        INSERT INTO bronze.application_train
        SELECT *, GETDATE()
        FROM #application_train_stage;

        SET @row_count = @@ROWCOUNT;
        DROP TABLE #application_train_stage;

        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        SET @table_count += 1;

        PRINT '   Rows loaded: ' + CAST(@row_count AS NVARCHAR) + 
              ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        SET @error_count += 1;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 2. application_test
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'bronze.load_bronze',
            @layer = 'bronze',
            @table_name = 'application_test',
            @batch_id = @batch_id,
            @run_id = @run_id OUTPUT;

        SET @start_time = SYSDATETIME();
        PRINT '>> Loading: bronze.application_test';

        TRUNCATE TABLE bronze.application_test;

        CREATE TABLE #application_test_stage (
            SK_ID_CURR NVARCHAR(255),
            NAME_CONTRACT_TYPE NVARCHAR(255), CODE_GENDER NVARCHAR(255),
            FLAG_OWN_CAR NVARCHAR(255), FLAG_OWN_REALTY NVARCHAR(255),
            CNT_CHILDREN NVARCHAR(255),
            AMT_INCOME_TOTAL NVARCHAR(255), AMT_CREDIT NVARCHAR(255),
            AMT_ANNUITY NVARCHAR(255), AMT_GOODS_PRICE NVARCHAR(255),
            NAME_TYPE_SUITE NVARCHAR(255), NAME_INCOME_TYPE NVARCHAR(255),
            NAME_EDUCATION_TYPE NVARCHAR(255), NAME_FAMILY_STATUS NVARCHAR(255),
            NAME_HOUSING_TYPE NVARCHAR(255),
            REGION_POPULATION_RELATIVE NVARCHAR(255),
            DAYS_BIRTH NVARCHAR(255), DAYS_EMPLOYED NVARCHAR(255),
            DAYS_REGISTRATION NVARCHAR(255), DAYS_ID_PUBLISH NVARCHAR(255),
            OWN_CAR_AGE NVARCHAR(255),
            FLAG_MOBIL NVARCHAR(255), FLAG_EMP_PHONE NVARCHAR(255),
            FLAG_WORK_PHONE NVARCHAR(255), FLAG_CONT_MOBILE NVARCHAR(255),
            FLAG_PHONE NVARCHAR(255), FLAG_EMAIL NVARCHAR(255),
            OCCUPATION_TYPE NVARCHAR(255), CNT_FAM_MEMBERS NVARCHAR(255),
            REGION_RATING_CLIENT NVARCHAR(255), REGION_RATING_CLIENT_W_CITY NVARCHAR(255),
            WEEKDAY_APPR_PROCESS_START NVARCHAR(255), HOUR_APPR_PROCESS_START NVARCHAR(255),
            REG_REGION_NOT_LIVE_REGION NVARCHAR(255), REG_REGION_NOT_WORK_REGION NVARCHAR(255),
            LIVE_REGION_NOT_WORK_REGION NVARCHAR(255),
            REG_CITY_NOT_LIVE_CITY NVARCHAR(255), REG_CITY_NOT_WORK_CITY NVARCHAR(255),
            LIVE_CITY_NOT_WORK_CITY NVARCHAR(255),
            ORGANIZATION_TYPE NVARCHAR(255),
            EXT_SOURCE_1 NVARCHAR(255), EXT_SOURCE_2 NVARCHAR(255), EXT_SOURCE_3 NVARCHAR(255),
            APARTMENTS_AVG NVARCHAR(255), BASEMENTAREA_AVG NVARCHAR(255),
            YEARS_BEGINEXPLUATATION_AVG NVARCHAR(255), YEARS_BUILD_AVG NVARCHAR(255),
            COMMONAREA_AVG NVARCHAR(255), ELEVATORS_AVG NVARCHAR(255),
            ENTRANCES_AVG NVARCHAR(255), FLOORSMAX_AVG NVARCHAR(255),
            FLOORSMIN_AVG NVARCHAR(255), LANDAREA_AVG NVARCHAR(255),
            LIVINGAPARTMENTS_AVG NVARCHAR(255), LIVINGAREA_AVG NVARCHAR(255),
            NONLIVINGAPARTMENTS_AVG NVARCHAR(255), NONLIVINGAREA_AVG NVARCHAR(255),
            APARTMENTS_MODE NVARCHAR(255), BASEMENTAREA_MODE NVARCHAR(255),
            YEARS_BEGINEXPLUATATION_MODE NVARCHAR(255), YEARS_BUILD_MODE NVARCHAR(255),
            COMMONAREA_MODE NVARCHAR(255), ELEVATORS_MODE NVARCHAR(255),
            ENTRANCES_MODE NVARCHAR(255), FLOORSMAX_MODE NVARCHAR(255),
            FLOORSMIN_MODE NVARCHAR(255), LANDAREA_MODE NVARCHAR(255),
            LIVINGAPARTMENTS_MODE NVARCHAR(255), LIVINGAREA_MODE NVARCHAR(255),
            NONLIVINGAPARTMENTS_MODE NVARCHAR(255), NONLIVINGAREA_MODE NVARCHAR(255),
            APARTMENTS_MEDI NVARCHAR(255), BASEMENTAREA_MEDI NVARCHAR(255),
            YEARS_BEGINEXPLUATATION_MEDI NVARCHAR(255), YEARS_BUILD_MEDI NVARCHAR(255),
            COMMONAREA_MEDI NVARCHAR(255), ELEVATORS_MEDI NVARCHAR(255),
            ENTRANCES_MEDI NVARCHAR(255), FLOORSMAX_MEDI NVARCHAR(255),
            FLOORSMIN_MEDI NVARCHAR(255), LANDAREA_MEDI NVARCHAR(255),
            LIVINGAPARTMENTS_MEDI NVARCHAR(255), LIVINGAREA_MEDI NVARCHAR(255),
            NONLIVINGAPARTMENTS_MEDI NVARCHAR(255), NONLIVINGAREA_MEDI NVARCHAR(255),
            FONDKAPREMONT_MODE NVARCHAR(255), HOUSETYPE_MODE NVARCHAR(255),
            TOTALAREA_MODE NVARCHAR(255),
            WALLSMATERIAL_MODE NVARCHAR(255), EMERGENCYSTATE_MODE NVARCHAR(255),
            OBS_30_CNT_SOCIAL_CIRCLE NVARCHAR(255), DEF_30_CNT_SOCIAL_CIRCLE NVARCHAR(255),
            OBS_60_CNT_SOCIAL_CIRCLE NVARCHAR(255), DEF_60_CNT_SOCIAL_CIRCLE NVARCHAR(255),
            DAYS_LAST_PHONE_CHANGE NVARCHAR(255),
            FLAG_DOCUMENT_2 NVARCHAR(255), FLAG_DOCUMENT_3 NVARCHAR(255),
            FLAG_DOCUMENT_4 NVARCHAR(255), FLAG_DOCUMENT_5 NVARCHAR(255),
            FLAG_DOCUMENT_6 NVARCHAR(255), FLAG_DOCUMENT_7 NVARCHAR(255),
            FLAG_DOCUMENT_8 NVARCHAR(255), FLAG_DOCUMENT_9 NVARCHAR(255),
            FLAG_DOCUMENT_10 NVARCHAR(255), FLAG_DOCUMENT_11 NVARCHAR(255),
            FLAG_DOCUMENT_12 NVARCHAR(255), FLAG_DOCUMENT_13 NVARCHAR(255),
            FLAG_DOCUMENT_14 NVARCHAR(255), FLAG_DOCUMENT_15 NVARCHAR(255),
            FLAG_DOCUMENT_16 NVARCHAR(255), FLAG_DOCUMENT_17 NVARCHAR(255),
            FLAG_DOCUMENT_18 NVARCHAR(255), FLAG_DOCUMENT_19 NVARCHAR(255),
            FLAG_DOCUMENT_20 NVARCHAR(255), FLAG_DOCUMENT_21 NVARCHAR(255),
            AMT_REQ_CREDIT_BUREAU_HOUR NVARCHAR(255), AMT_REQ_CREDIT_BUREAU_DAY NVARCHAR(255),
            AMT_REQ_CREDIT_BUREAU_WEEK NVARCHAR(255), AMT_REQ_CREDIT_BUREAU_MON NVARCHAR(255),
            AMT_REQ_CREDIT_BUREAU_QRT NVARCHAR(255), AMT_REQ_CREDIT_BUREAU_YEAR NVARCHAR(255)
        );

        BULK INSERT #application_test_stage
        FROM 'C:\home-credit-default-risk\application_test.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            CODEPAGE = '65001',
            TABLOCK
        );

        INSERT INTO bronze.application_test
        SELECT *, GETDATE()
        FROM #application_test_stage;

        SET @row_count = @@ROWCOUNT;
        DROP TABLE #application_test_stage;

        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        SET @table_count += 1;

        PRINT '   Rows loaded: ' + CAST(@row_count AS NVARCHAR) + 
              ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        SET @error_count += 1;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 3. bureau
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'bronze.load_bronze',
            @layer = 'bronze',
            @table_name = 'bureau',
            @batch_id = @batch_id,
            @run_id = @run_id OUTPUT;

        SET @start_time = SYSDATETIME();
        PRINT '>> Loading: bronze.bureau';

        TRUNCATE TABLE bronze.bureau;

        CREATE TABLE #bureau_stage (
            SK_ID_CURR NVARCHAR(255), SK_ID_BUREAU NVARCHAR(255),
            CREDIT_ACTIVE NVARCHAR(255), CREDIT_CURRENCY NVARCHAR(255),
            DAYS_CREDIT NVARCHAR(255), CREDIT_DAY_OVERDUE NVARCHAR(255),
            DAYS_CREDIT_ENDDATE NVARCHAR(255), DAYS_ENDDATE_FACT NVARCHAR(255),
            AMT_CREDIT_MAX_OVERDUE NVARCHAR(255), CNT_CREDIT_PROLONG NVARCHAR(255),
            AMT_CREDIT_SUM NVARCHAR(255), AMT_CREDIT_SUM_DEBT NVARCHAR(255),
            AMT_CREDIT_SUM_LIMIT NVARCHAR(255), AMT_CREDIT_SUM_OVERDUE NVARCHAR(255),
            CREDIT_TYPE NVARCHAR(255), DAYS_CREDIT_UPDATE NVARCHAR(255),
            AMT_ANNUITY NVARCHAR(255)
        );

        BULK INSERT #bureau_stage
        FROM 'C:\home-credit-default-risk\bureau.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);

        INSERT INTO bronze.bureau SELECT *, GETDATE() FROM #bureau_stage;
        SET @row_count = @@ROWCOUNT;
        DROP TABLE #bureau_stage;

        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        SET @table_count += 1;
        PRINT '   Rows loaded: ' + CAST(@row_count AS NVARCHAR) + 
              ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        SET @error_count += 1;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 4. bureau_balance
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'bronze.load_bronze',
            @layer = 'bronze',
            @table_name = 'bureau_balance',
            @batch_id = @batch_id,
            @run_id = @run_id OUTPUT;

        SET @start_time = SYSDATETIME();
        PRINT '>> Loading: bronze.bureau_balance';

        TRUNCATE TABLE bronze.bureau_balance;

        CREATE TABLE #bureau_balance_stage (
            SK_ID_BUREAU NVARCHAR(255), MONTHS_BALANCE NVARCHAR(255), STATUS NVARCHAR(255)
        );

        BULK INSERT #bureau_balance_stage
        FROM 'C:\home-credit-default-risk\bureau_balance.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);

        INSERT INTO bronze.bureau_balance SELECT *, GETDATE() FROM #bureau_balance_stage;
        SET @row_count = @@ROWCOUNT;
        DROP TABLE #bureau_balance_stage;

        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        SET @table_count += 1;
        PRINT '   Rows loaded: ' + CAST(@row_count AS NVARCHAR) + 
              ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        SET @error_count += 1;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 5. previous_application
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'bronze.load_bronze',
            @layer = 'bronze',
            @table_name = 'previous_application',
            @batch_id = @batch_id,
            @run_id = @run_id OUTPUT;

        SET @start_time = SYSDATETIME();
        PRINT '>> Loading: bronze.previous_application';

        TRUNCATE TABLE bronze.previous_application;

        CREATE TABLE #previous_application_stage (
            SK_ID_PREV NVARCHAR(255), SK_ID_CURR NVARCHAR(255),
            NAME_CONTRACT_TYPE NVARCHAR(255),
            AMT_ANNUITY NVARCHAR(255), AMT_APPLICATION NVARCHAR(255),
            AMT_CREDIT NVARCHAR(255), AMT_DOWN_PAYMENT NVARCHAR(255),
            AMT_GOODS_PRICE NVARCHAR(255),
            WEEKDAY_APPR_PROCESS_START NVARCHAR(255), HOUR_APPR_PROCESS_START NVARCHAR(255),
            FLAG_LAST_APPL_PER_CONTRACT NVARCHAR(255), NFLAG_LAST_APPL_IN_DAY NVARCHAR(255),
            RATE_DOWN_PAYMENT NVARCHAR(255), RATE_INTEREST_PRIMARY NVARCHAR(255),
            RATE_INTEREST_PRIVILEGED NVARCHAR(255),
            NAME_CASH_LOAN_PURPOSE NVARCHAR(255), NAME_CONTRACT_STATUS NVARCHAR(255),
            DAYS_DECISION NVARCHAR(255), NAME_PAYMENT_TYPE NVARCHAR(255),
            CODE_REJECT_REASON NVARCHAR(255), NAME_TYPE_SUITE NVARCHAR(255),
            NAME_CLIENT_TYPE NVARCHAR(255), NAME_GOODS_CATEGORY NVARCHAR(255),
            NAME_PORTFOLIO NVARCHAR(255), NAME_PRODUCT_TYPE NVARCHAR(255),
            CHANNEL_TYPE NVARCHAR(255), SELLERPLACE_AREA NVARCHAR(255),
            NAME_SELLER_INDUSTRY NVARCHAR(255), CNT_PAYMENT NVARCHAR(255),
            NAME_YIELD_GROUP NVARCHAR(255), PRODUCT_COMBINATION NVARCHAR(255),
            DAYS_FIRST_DRAWING NVARCHAR(255), DAYS_FIRST_DUE NVARCHAR(255),
            DAYS_LAST_DUE_1ST_VERSION NVARCHAR(255), DAYS_LAST_DUE NVARCHAR(255),
            DAYS_TERMINATION NVARCHAR(255), NFLAG_INSURED_ON_APPROVAL NVARCHAR(255)
        );

        BULK INSERT #previous_application_stage
        FROM 'C:\home-credit-default-risk\previous_application.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);

        INSERT INTO bronze.previous_application SELECT *, GETDATE() FROM #previous_application_stage;
        SET @row_count = @@ROWCOUNT;
        DROP TABLE #previous_application_stage;

        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        SET @table_count += 1;
        PRINT '   Rows loaded: ' + CAST(@row_count AS NVARCHAR) + 
              ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        SET @error_count += 1;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 6. installments_payments
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'bronze.load_bronze',
            @layer = 'bronze',
            @table_name = 'installments_payments',
            @batch_id = @batch_id,
            @run_id = @run_id OUTPUT;

        SET @start_time = SYSDATETIME();
        PRINT '>> Loading: bronze.installments_payments';

        TRUNCATE TABLE bronze.installments_payments;

        CREATE TABLE #installments_payments_stage (
            SK_ID_PREV NVARCHAR(255), SK_ID_CURR NVARCHAR(255),
            NUM_INSTALMENT_VERSION NVARCHAR(255), NUM_INSTALMENT_NUMBER NVARCHAR(255),
            DAYS_INSTALMENT NVARCHAR(255), DAYS_ENTRY_PAYMENT NVARCHAR(255),
            AMT_INSTALMENT NVARCHAR(255), AMT_PAYMENT NVARCHAR(255)
        );

        BULK INSERT #installments_payments_stage
        FROM 'C:\home-credit-default-risk\installments_payments.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);

        INSERT INTO bronze.installments_payments SELECT *, GETDATE() FROM #installments_payments_stage;
        SET @row_count = @@ROWCOUNT;
        DROP TABLE #installments_payments_stage;

        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        SET @table_count += 1;
        PRINT '   Rows loaded: ' + CAST(@row_count AS NVARCHAR) + 
              ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        SET @error_count += 1;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 7. POS_CASH_balance
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'bronze.load_bronze',
            @layer = 'bronze',
            @table_name = 'POS_CASH_balance',
            @batch_id = @batch_id,
            @run_id = @run_id OUTPUT;

        SET @start_time = SYSDATETIME();
        PRINT '>> Loading: bronze.POS_CASH_balance';

        TRUNCATE TABLE bronze.POS_CASH_balance;

        CREATE TABLE #POS_CASH_balance_stage (
            SK_ID_PREV NVARCHAR(255), SK_ID_CURR NVARCHAR(255),
            MONTHS_BALANCE NVARCHAR(255), CNT_INSTALMENT NVARCHAR(255),
            CNT_INSTALMENT_FUTURE NVARCHAR(255), NAME_CONTRACT_STATUS NVARCHAR(255),
            SK_DPD NVARCHAR(255), SK_DPD_DEF NVARCHAR(255)
        );

        BULK INSERT #POS_CASH_balance_stage
        FROM 'C:\home-credit-default-risk\POS_CASH_balance.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);

        INSERT INTO bronze.POS_CASH_balance SELECT *, GETDATE() FROM #POS_CASH_balance_stage;
        SET @row_count = @@ROWCOUNT;
        DROP TABLE #POS_CASH_balance_stage;

        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        SET @table_count += 1;
        PRINT '   Rows loaded: ' + CAST(@row_count AS NVARCHAR) + 
              ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        SET @error_count += 1;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 8. credit_card_balance
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'bronze.load_bronze',
            @layer = 'bronze',
            @table_name = 'credit_card_balance',
            @batch_id = @batch_id,
            @run_id = @run_id OUTPUT;

        SET @start_time = SYSDATETIME();
        PRINT '>> Loading: bronze.credit_card_balance';

        TRUNCATE TABLE bronze.credit_card_balance;

        CREATE TABLE #credit_card_balance_stage (
            SK_ID_PREV NVARCHAR(255), SK_ID_CURR NVARCHAR(255),
            MONTHS_BALANCE NVARCHAR(255), AMT_BALANCE NVARCHAR(255),
            AMT_CREDIT_LIMIT_ACTUAL NVARCHAR(255),
            AMT_DRAWINGS_ATM_CURRENT NVARCHAR(255), AMT_DRAWINGS_CURRENT NVARCHAR(255),
            AMT_DRAWINGS_OTHER_CURRENT NVARCHAR(255), AMT_DRAWINGS_POS_CURRENT NVARCHAR(255),
            AMT_INST_MIN_REGULARITY NVARCHAR(255), AMT_PAYMENT_CURRENT NVARCHAR(255),
            AMT_PAYMENT_TOTAL_CURRENT NVARCHAR(255), AMT_RECEIVABLE_PRINCIPAL NVARCHAR(255),
            AMT_RECIVABLE NVARCHAR(255), AMT_TOTAL_RECEIVABLE NVARCHAR(255),
            CNT_DRAWINGS_ATM_CURRENT NVARCHAR(255), CNT_DRAWINGS_CURRENT NVARCHAR(255),
            CNT_DRAWINGS_OTHER_CURRENT NVARCHAR(255), CNT_DRAWINGS_POS_CURRENT NVARCHAR(255),
            CNT_INSTALMENT_MATURE_CUM NVARCHAR(255), NAME_CONTRACT_STATUS NVARCHAR(255),
            SK_DPD NVARCHAR(255), SK_DPD_DEF NVARCHAR(255)
        );

        BULK INSERT #credit_card_balance_stage
        FROM 'C:\home-credit-default-risk\credit_card_balance.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);

        INSERT INTO bronze.credit_card_balance SELECT *, GETDATE() FROM #credit_card_balance_stage;
        SET @row_count = @@ROWCOUNT;
        DROP TABLE #credit_card_balance_stage;

        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        SET @table_count += 1;
        PRINT '   Rows loaded: ' + CAST(@row_count AS NVARCHAR) + 
              ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        SET @error_count += 1;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 9. sample_submission
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'bronze.load_bronze',
            @layer = 'bronze',
            @table_name = 'sample_submission',
            @batch_id = @batch_id,
            @run_id = @run_id OUTPUT;

        SET @start_time = SYSDATETIME();
        PRINT '>> Loading: bronze.sample_submission';

        TRUNCATE TABLE bronze.sample_submission;

        CREATE TABLE #sample_submission_stage (
            SK_ID_CURR NVARCHAR(255), TARGET NVARCHAR(255)
        );

        BULK INSERT #sample_submission_stage
        FROM 'C:\home-credit-default-risk\sample_submission.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);

        INSERT INTO bronze.sample_submission SELECT *, GETDATE() FROM #sample_submission_stage;
        SET @row_count = @@ROWCOUNT;
        DROP TABLE #sample_submission_stage;

        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        SET @table_count += 1;
        PRINT '   Rows loaded: ' + CAST(@row_count AS NVARCHAR) + 
              ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        SET @error_count += 1;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 10. HomeCredit_columns_description
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'bronze.load_bronze',
            @layer = 'bronze',
            @table_name = 'HomeCredit_columns_description',
            @batch_id = @batch_id,
            @run_id = @run_id OUTPUT;

        SET @start_time = SYSDATETIME();
        PRINT '>> Loading: bronze.HomeCredit_columns_description';

        TRUNCATE TABLE bronze.HomeCredit_columns_description;

        CREATE TABLE #HomeCredit_columns_description_stage (
            [Row] NVARCHAR(255), [Table] NVARCHAR(255),
            [Column] NVARCHAR(255), [Description] NVARCHAR(MAX),
            [Special] NVARCHAR(MAX)
        );

        BULK INSERT #HomeCredit_columns_description_stage
        FROM 'C:\home-credit-default-risk\HomeCredit_columns_description.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);

        INSERT INTO bronze.HomeCredit_columns_description SELECT *, GETDATE() FROM #HomeCredit_columns_description_stage;
        SET @row_count = @@ROWCOUNT;
        DROP TABLE #HomeCredit_columns_description_stage;

        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        SET @table_count += 1;
        PRINT '   Rows loaded: ' + CAST(@row_count AS NVARCHAR) + 
              ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        SET @error_count += 1;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- SUMMARY
    -- ==================================================================
    PRINT '================================================================';
    PRINT 'BRONZE LAYER LOAD COMPLETED';
    PRINT 'Batch ID    : ' + CAST(@batch_id AS NVARCHAR(50));
    PRINT 'Tables OK   : ' + CAST(@table_count AS NVARCHAR);
    PRINT 'Errors      : ' + CAST(@error_count AS NVARCHAR);
    PRINT 'Completed   : ' + CONVERT(NVARCHAR, SYSDATETIME(), 120);
    PRINT '================================================================';

END;
GO