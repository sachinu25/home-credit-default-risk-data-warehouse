USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: Load Silver Layer - Application Test
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_application_test
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @start_time DATETIME,
        @end_time DATETIME;

    BEGIN TRY

        SET @start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Silver Table: silver.application_test';
        PRINT '================================================';

        PRINT '>> Truncating Table: silver.application_test';
        TRUNCATE TABLE silver.application_test;

        PRINT '>> Inserting cleaned data into silver.application_test';

        INSERT INTO silver.application_test (
            sk_id_curr,
            contract_type,
            gender,
            owns_car,
            owns_realty,
            children_count,
            income_total,
            credit_amount,
            annuity_amount,
            goods_price,
            type_suite,
            income_type,
            education_type,
            family_status,
            housing_type,
            region_population_relative,
            days_birth,
            age_years,
            days_employed,
            employment_years,
            days_registration,
            days_id_publish,
            own_car_age,
            flag_mobile,
            flag_emp_phone,
            flag_work_phone,
            flag_cont_mobile,
            flag_phone,
            flag_email,
            occupation_type,
            family_members_count,
            region_rating_client,
            region_rating_client_w_city,
            weekday_application_start,
            hour_application_start,
            organization_type,
            ext_source_1,
            ext_source_2,
            ext_source_3,
            social_circle_obs_30,
            social_circle_def_30,
            social_circle_obs_60,
            social_circle_def_60,
            days_last_phone_change,
            req_credit_bureau_hour,
            req_credit_bureau_day,
            req_credit_bureau_week,
            req_credit_bureau_month,
            req_credit_bureau_quarter,
            req_credit_bureau_year,
            credit_income_ratio,
            annuity_income_ratio,
            goods_credit_ratio,
            dwh_load_date
        )
        SELECT
            TRY_CAST(NULLIF(SK_ID_CURR, '') AS INT),

            UPPER(TRIM(NULLIF(NAME_CONTRACT_TYPE, ''))),

            CASE
                WHEN CODE_GENDER = 'M' THEN 'Male'
                WHEN CODE_GENDER = 'F' THEN 'Female'
                WHEN CODE_GENDER = 'XNA' THEN 'Unknown'
                ELSE 'Unknown'
            END,

            CASE
                WHEN FLAG_OWN_CAR = 'Y' THEN 'Yes'
                WHEN FLAG_OWN_CAR = 'N' THEN 'No'
                ELSE 'Unknown'
            END,

            CASE
                WHEN FLAG_OWN_REALTY = 'Y' THEN 'Yes'
                WHEN FLAG_OWN_REALTY = 'N' THEN 'No'
                ELSE 'Unknown'
            END,

            TRY_CAST(NULLIF(CNT_CHILDREN, '') AS INT),

            TRY_CAST(NULLIF(AMT_INCOME_TOTAL, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_CREDIT, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_ANNUITY, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(AMT_GOODS_PRICE, '') AS DECIMAL(18,2)),

            TRIM(NULLIF(NAME_TYPE_SUITE, '')),
            TRIM(NULLIF(NAME_INCOME_TYPE, '')),
            TRIM(NULLIF(NAME_EDUCATION_TYPE, '')),
            TRIM(NULLIF(NAME_FAMILY_STATUS, '')),
            TRIM(NULLIF(NAME_HOUSING_TYPE, '')),

            TRY_CAST(NULLIF(REGION_POPULATION_RELATIVE, '') AS DECIMAL(18,10)),

            TRY_CAST(NULLIF(DAYS_BIRTH, '') AS INT),

            CASE
                WHEN TRY_CAST(NULLIF(DAYS_BIRTH, '') AS INT) IS NOT NULL
                    THEN ABS(TRY_CAST(NULLIF(DAYS_BIRTH, '') AS DECIMAL(18,2))) / 365.25
                ELSE NULL
            END,

            TRY_CAST(NULLIF(DAYS_EMPLOYED, '') AS INT),

            CASE
                WHEN TRY_CAST(NULLIF(DAYS_EMPLOYED, '') AS INT) IS NULL THEN NULL
                WHEN TRY_CAST(NULLIF(DAYS_EMPLOYED, '') AS INT) = 365243 THEN NULL
                ELSE ABS(TRY_CAST(NULLIF(DAYS_EMPLOYED, '') AS DECIMAL(18,2))) / 365.25
            END,

            TRY_CAST(NULLIF(DAYS_REGISTRATION, '') AS DECIMAL(18,2)),
            TRY_CAST(NULLIF(DAYS_ID_PUBLISH, '') AS INT),

            TRY_CAST(NULLIF(OWN_CAR_AGE, '') AS DECIMAL(10,2)),

            TRY_CAST(NULLIF(FLAG_MOBIL, '') AS TINYINT),
            TRY_CAST(NULLIF(FLAG_EMP_PHONE, '') AS TINYINT),
            TRY_CAST(NULLIF(FLAG_WORK_PHONE, '') AS TINYINT),
            TRY_CAST(NULLIF(FLAG_CONT_MOBILE, '') AS TINYINT),
            TRY_CAST(NULLIF(FLAG_PHONE, '') AS TINYINT),
            TRY_CAST(NULLIF(FLAG_EMAIL, '') AS TINYINT),

            TRIM(NULLIF(OCCUPATION_TYPE, '')),

            TRY_CAST(NULLIF(CNT_FAM_MEMBERS, '') AS DECIMAL(10,2)),

            TRY_CAST(NULLIF(REGION_RATING_CLIENT, '') AS TINYINT),
            TRY_CAST(NULLIF(REGION_RATING_CLIENT_W_CITY, '') AS TINYINT),

            TRIM(NULLIF(WEEKDAY_APPR_PROCESS_START, '')),
            TRY_CAST(NULLIF(HOUR_APPR_PROCESS_START, '') AS TINYINT),

            TRIM(NULLIF(ORGANIZATION_TYPE, '')),

            TRY_CAST(NULLIF(EXT_SOURCE_1, '') AS DECIMAL(18,10)),
            TRY_CAST(NULLIF(EXT_SOURCE_2, '') AS DECIMAL(18,10)),
            TRY_CAST(NULLIF(EXT_SOURCE_3, '') AS DECIMAL(18,10)),

            TRY_CAST(NULLIF(OBS_30_CNT_SOCIAL_CIRCLE, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(DEF_30_CNT_SOCIAL_CIRCLE, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(OBS_60_CNT_SOCIAL_CIRCLE, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(DEF_60_CNT_SOCIAL_CIRCLE, '') AS DECIMAL(10,2)),

            TRY_CAST(NULLIF(DAYS_LAST_PHONE_CHANGE, '') AS DECIMAL(10,2)),

            TRY_CAST(NULLIF(AMT_REQ_CREDIT_BUREAU_HOUR, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(AMT_REQ_CREDIT_BUREAU_DAY, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(AMT_REQ_CREDIT_BUREAU_WEEK, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(AMT_REQ_CREDIT_BUREAU_MON, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(AMT_REQ_CREDIT_BUREAU_QRT, '') AS DECIMAL(10,2)),
            TRY_CAST(NULLIF(AMT_REQ_CREDIT_BUREAU_YEAR, '') AS DECIMAL(10,2)),

            CASE
                WHEN TRY_CAST(NULLIF(AMT_INCOME_TOTAL, '') AS DECIMAL(18,2)) > 0
                    THEN TRY_CAST(NULLIF(AMT_CREDIT, '') AS DECIMAL(18,2)) /
                         TRY_CAST(NULLIF(AMT_INCOME_TOTAL, '') AS DECIMAL(18,2))
                ELSE NULL
            END,

            CASE
                WHEN TRY_CAST(NULLIF(AMT_INCOME_TOTAL, '') AS DECIMAL(18,2)) > 0
                    THEN TRY_CAST(NULLIF(AMT_ANNUITY, '') AS DECIMAL(18,2)) /
                         TRY_CAST(NULLIF(AMT_INCOME_TOTAL, '') AS DECIMAL(18,2))
                ELSE NULL
            END,

            CASE
                WHEN TRY_CAST(NULLIF(AMT_CREDIT, '') AS DECIMAL(18,2)) > 0
                    THEN TRY_CAST(NULLIF(AMT_GOODS_PRICE, '') AS DECIMAL(18,2)) /
                         TRY_CAST(NULLIF(AMT_CREDIT, '') AS DECIMAL(18,2))
                ELSE NULL
            END,

            GETDATE()

        FROM bronze.application_test;

        SET @end_time = GETDATE();

        PRINT '>> Silver application_test load completed';
        PRINT '>> Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';

    END TRY

    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR OCCURRED WHILE LOADING silver.application_test';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT '================================================';
    END CATCH
END;
GO