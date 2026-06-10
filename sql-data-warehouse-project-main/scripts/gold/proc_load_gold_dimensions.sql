USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: Load Gold Dimensions
===============================================================================
Purpose:
    Populates all Gold dimension tables:
    1. dim_customer  — SCD Type 2 MERGE from silver.application_train
    2. dim_time      — Calendar date generation
    3. dim_credit    — Credit type lookup population
    4. dim_region    — Region rating lookup population
    5. dim_income    — Income band lookup population

Enterprise Features:
    ✓ SCD Type 2 with effective_date/end_date/is_current
    ✓ Composite risk score calculation
    ✓ Age band derivation
    ✓ Audit logging integration
    ✓ Row count tracking

Author:     Anumodit Shukla
Created:    2026 — Enterprise star schema
===============================================================================
*/

CREATE OR ALTER PROCEDURE gold.load_dimensions
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE 
        @batch_id       UNIQUEIDENTIFIER = NEWID(),
        @run_id         INT,
        @row_count      INT;

    PRINT '================================================================';
    PRINT 'GOLD DIMENSION LOAD — Batch: ' + CAST(@batch_id AS NVARCHAR(50));
    PRINT '================================================================';

    -- ==================================================================
    -- 1. dim_time — Calendar Dimension
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'gold.load_dimensions',
            @layer = 'gold', @table_name = 'dim_time',
            @batch_id = @batch_id, @run_id = @run_id OUTPUT;

        PRINT '>> Loading: gold.dim_time';

        -- Only populate if empty (calendar is static)
        IF NOT EXISTS (SELECT 1 FROM gold.dim_time)
        BEGIN

            DECLARE @start_date DATE = '2010-01-01';
            DECLARE @end_date   DATE = '2030-12-31';

            ;WITH DateCTE AS (
                SELECT @start_date AS dt
                UNION ALL
                SELECT DATEADD(DAY, 1, dt)
                FROM DateCTE
                WHERE dt < @end_date
            )
            INSERT INTO gold.dim_time (
                time_key, full_date,
                day_of_week, day_name, day_of_month, day_of_year,
                is_weekend, is_weekday,
                week_of_year, iso_week,
                month_number, month_name, month_short,
                quarter_number, quarter_name,
                calendar_year, year_month, year_quarter,
                fiscal_year, fiscal_quarter, fiscal_quarter_name
            )
            SELECT
                CAST(FORMAT(dt, 'yyyyMMdd') AS INT)         AS time_key,
                dt                                           AS full_date,

                DATEPART(WEEKDAY, dt)                        AS day_of_week,
                DATENAME(WEEKDAY, dt)                        AS day_name,
                DAY(dt)                                      AS day_of_month,
                DATEPART(DAYOFYEAR, dt)                      AS day_of_year,

                CASE WHEN DATEPART(WEEKDAY, dt) IN (1,7) THEN 1 ELSE 0 END AS is_weekend,
                CASE WHEN DATEPART(WEEKDAY, dt) IN (1,7) THEN 0 ELSE 1 END AS is_weekday,

                DATEPART(WEEK, dt)                           AS week_of_year,
                DATEPART(ISO_WEEK, dt)                       AS iso_week,

                MONTH(dt)                                    AS month_number,
                DATENAME(MONTH, dt)                          AS month_name,
                LEFT(DATENAME(MONTH, dt), 3)                 AS month_short,

                DATEPART(QUARTER, dt)                        AS quarter_number,
                'Q' + CAST(DATEPART(QUARTER, dt) AS NVARCHAR) AS quarter_name,

                YEAR(dt)                                     AS calendar_year,
                FORMAT(dt, 'yyyy-MM')                        AS year_month,
                CAST(YEAR(dt) AS NVARCHAR) + '-Q' + CAST(DATEPART(QUARTER, dt) AS NVARCHAR) AS year_quarter,

                -- Fiscal year (July start)
                CASE WHEN MONTH(dt) >= 7 THEN YEAR(dt) + 1 ELSE YEAR(dt) END AS fiscal_year,
                CASE 
                    WHEN MONTH(dt) IN (7,8,9)   THEN 1
                    WHEN MONTH(dt) IN (10,11,12) THEN 2
                    WHEN MONTH(dt) IN (1,2,3)   THEN 3
                    ELSE 4
                END AS fiscal_quarter,
                'FQ' + CAST(
                    CASE 
                        WHEN MONTH(dt) IN (7,8,9)   THEN 1
                        WHEN MONTH(dt) IN (10,11,12) THEN 2
                        WHEN MONTH(dt) IN (1,2,3)   THEN 3
                        ELSE 4
                    END AS NVARCHAR
                ) AS fiscal_quarter_name

            FROM DateCTE
            OPTION (MAXRECURSION 0);

            SET @row_count = @@ROWCOUNT;

        END
        ELSE
        BEGIN
            SET @row_count = 0;
            PRINT '   dim_time already populated — skipping';
        END;

        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        PRINT '   Rows: ' + CAST(@row_count AS NVARCHAR);

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 2. dim_credit — Credit Type Lookup
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'gold.load_dimensions',
            @layer = 'gold', @table_name = 'dim_credit',
            @batch_id = @batch_id, @run_id = @run_id OUTPUT;

        PRINT '>> Loading: gold.dim_credit';

        TRUNCATE TABLE gold.dim_credit;

        INSERT INTO gold.dim_credit (credit_type, credit_category, risk_weight, description)
        SELECT DISTINCT
            credit_type,
            CASE
                WHEN credit_type IN ('Consumer credit', 'Car loan')              THEN 'Consumer'
                WHEN credit_type IN ('Credit card')                              THEN 'Revolving'
                WHEN credit_type IN ('Mortgage')                                 THEN 'Mortgage'
                WHEN credit_type IN ('Microloan', 'Loan for purchase of shares') THEN 'Micro/Investment'
                WHEN credit_type IN ('Interbank credit')                         THEN 'Wholesale'
                ELSE 'Other'
            END AS credit_category,
            CASE
                WHEN credit_type = 'Mortgage'                   THEN 0.50
                WHEN credit_type = 'Consumer credit'            THEN 1.00
                WHEN credit_type = 'Credit card'                THEN 1.50
                WHEN credit_type = 'Car loan'                   THEN 0.75
                WHEN credit_type = 'Microloan'                  THEN 2.00
                WHEN credit_type = 'Loan for purchase of shares'THEN 1.50
                ELSE 1.00
            END AS risk_weight,
            'Credit type from bureau data: ' + credit_type
        FROM silver.bureau
        WHERE credit_type IS NOT NULL;

        SET @row_count = @@ROWCOUNT;
        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        PRINT '   Rows: ' + CAST(@row_count AS NVARCHAR);

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 3. dim_region — Region Rating Lookup
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'gold.load_dimensions',
            @layer = 'gold', @table_name = 'dim_region',
            @batch_id = @batch_id, @run_id = @run_id OUTPUT;

        PRINT '>> Loading: gold.dim_region';

        TRUNCATE TABLE gold.dim_region;

        INSERT INTO gold.dim_region (region_rating, city_rating, region_tier, risk_classification)
        SELECT DISTINCT
            region_rating_client,
            region_rating_client_w_city,
            CASE region_rating_client
                WHEN 1 THEN 'Tier 1'
                WHEN 2 THEN 'Tier 2'
                WHEN 3 THEN 'Tier 3'
                ELSE 'Unknown'
            END,
            CASE 
                WHEN region_rating_client = 1 AND region_rating_client_w_city = 1 THEN 'Low'
                WHEN region_rating_client <= 2 AND region_rating_client_w_city <= 2 THEN 'Medium'
                ELSE 'High'
            END
        FROM silver.application_train
        WHERE region_rating_client IS NOT NULL
          AND region_rating_client_w_city IS NOT NULL;

        SET @row_count = @@ROWCOUNT;
        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        PRINT '   Rows: ' + CAST(@row_count AS NVARCHAR);

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 4. dim_income — Income Band Lookup
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'gold.load_dimensions',
            @layer = 'gold', @table_name = 'dim_income',
            @batch_id = @batch_id, @run_id = @run_id OUTPUT;

        PRINT '>> Loading: gold.dim_income';

        TRUNCATE TABLE gold.dim_income;

        INSERT INTO gold.dim_income (income_band, income_min, income_max, income_percentile, band_order)
        VALUES
            ('Below 50K',       0,          49999.99,   'Bottom 10%',   1),
            ('50K - 100K',      50000,      99999.99,   '10-25%',       2),
            ('100K - 150K',     100000,     149999.99,  '25-50%',       3),
            ('150K - 200K',     150000,     199999.99,  '50-65%',       4),
            ('200K - 300K',     200000,     299999.99,  '65-80%',       5),
            ('300K - 500K',     300000,     499999.99,  '80-90%',       6),
            ('500K - 1M',       500000,     999999.99,  '90-95%',       7),
            ('Above 1M',        1000000,    99999999.99,'Top 5%',       8);

        SET @row_count = @@ROWCOUNT;
        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        PRINT '   Rows: ' + CAST(@row_count AS NVARCHAR);

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 5. dim_customer — SCD Type 2 MERGE
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'gold.load_dimensions',
            @layer = 'gold', @table_name = 'dim_customer',
            @batch_id = @batch_id, @run_id = @run_id OUTPUT;

        PRINT '>> Loading: gold.dim_customer (SCD Type 2)';

        -- ============================================================
        -- SCD Type 2 Implementation:
        -- 1. For NEW customers → INSERT with is_current = 1
        -- 2. For CHANGED customers → Expire old row, INSERT new version
        -- 3. For UNCHANGED customers → No action
        -- ============================================================

        -- Step 1: Expire changed records
        UPDATE gold.dim_customer
        SET 
            end_date = CAST(GETDATE() AS DATE),
            is_current = 0,
            dwh_modified_date = SYSDATETIME()
        WHERE is_current = 1
          AND customer_id IN (
              SELECT s.sk_id_curr
              FROM silver.application_train s
              INNER JOIN gold.dim_customer d
                  ON s.sk_id_curr = d.customer_id
                 AND d.is_current = 1
              WHERE -- Detect changes in tracked attributes
                  ISNULL(s.gender, '')           != ISNULL(d.gender, '')
               OR ISNULL(s.family_status, '')    != ISNULL(d.family_status, '')
               OR ISNULL(s.education_type, '')   != ISNULL(d.education_type, '')
               OR ISNULL(s.occupation_type, '')  != ISNULL(d.occupation_type, '')
               OR ISNULL(s.income_type, '')      != ISNULL(d.income_type, '')
               OR ISNULL(s.housing_type, '')     != ISNULL(d.housing_type, '')
               OR ISNULL(s.owns_car, '')         != ISNULL(d.owns_car, '')
               OR ISNULL(s.owns_realty, '')       != ISNULL(d.owns_realty, '')
          );

        -- Step 2: Insert new and changed records
        INSERT INTO gold.dim_customer (
            customer_id,
            gender, age_years, age_band,
            family_status, children_count, family_members_count,
            education_type, occupation_type, income_type, organization_type,
            housing_type, owns_car, owns_realty,
            region_rating_client, region_rating_w_city,
            ext_source_1, ext_source_2, ext_source_3,
            composite_risk_score,
            effective_date, end_date, is_current
        )
        SELECT
            s.sk_id_curr,
            s.gender,
            s.age_years,

            -- Age Band Derivation
            CASE
                WHEN s.age_years < 25                   THEN '18-24'
                WHEN s.age_years >= 25 AND s.age_years < 35  THEN '25-34'
                WHEN s.age_years >= 35 AND s.age_years < 45  THEN '35-44'
                WHEN s.age_years >= 45 AND s.age_years < 55  THEN '45-54'
                WHEN s.age_years >= 55 AND s.age_years < 65  THEN '55-64'
                WHEN s.age_years >= 65                  THEN '65+'
                ELSE 'Unknown'
            END,

            s.family_status, s.children_count, s.family_members_count,
            s.education_type, s.occupation_type, s.income_type, s.organization_type,
            s.housing_type, s.owns_car, s.owns_realty,
            s.region_rating_client, s.region_rating_client_w_city,
            s.ext_source_1, s.ext_source_2, s.ext_source_3,

            -- Composite Risk Score: Weighted average of external sources
            -- Weights: EXT_SOURCE_2 (40%), EXT_SOURCE_3 (35%), EXT_SOURCE_1 (25%)
            CASE
                WHEN COALESCE(s.ext_source_1, s.ext_source_2, s.ext_source_3) IS NOT NULL
                THEN (
                    ISNULL(s.ext_source_1 * 0.25, 0) +
                    ISNULL(s.ext_source_2 * 0.40, 0) +
                    ISNULL(s.ext_source_3 * 0.35, 0)
                ) / (
                    CASE WHEN s.ext_source_1 IS NOT NULL THEN 0.25 ELSE 0 END +
                    CASE WHEN s.ext_source_2 IS NOT NULL THEN 0.40 ELSE 0 END +
                    CASE WHEN s.ext_source_3 IS NOT NULL THEN 0.35 ELSE 0 END
                )
                ELSE NULL
            END,

            CAST(GETDATE() AS DATE),    -- effective_date
            NULL,                        -- end_date (NULL = current)
            1                            -- is_current

        FROM silver.application_train s
        WHERE NOT EXISTS (
            SELECT 1 FROM gold.dim_customer d
            WHERE d.customer_id = s.sk_id_curr
              AND d.is_current = 1
        );

        SET @row_count = @@ROWCOUNT;
        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        PRINT '   Rows inserted/updated: ' + CAST(@row_count AS NVARCHAR);

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    PRINT '================================================================';
    PRINT 'GOLD DIMENSION LOAD COMPLETED';
    PRINT '================================================================';

END;
GO
