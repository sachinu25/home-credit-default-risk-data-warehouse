USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: Load Gold Fact Tables
===============================================================================
Purpose:
    Populates all Gold fact tables with surrogate key lookups to dimensions
    and derived risk metrics.

    1. fact_loan_application  — From silver.application_train
    2. fact_payment_behavior  — From silver.installments_payments (aggregated)
    3. fact_credit_history    — From silver.bureau (aggregated)
    4. fact_default_events    — From silver.application_train (filtered: default=1)

Enterprise Features:
    ✓ Surrogate key lookups to all dimensions
    ✓ Weighted risk scoring engine
    ✓ Payment/credit health scores
    ✓ Audit logging integration

Author:     Anumodit Shukla
Created:    2026 — Enterprise star schema fact loading
===============================================================================
*/

CREATE OR ALTER PROCEDURE gold.load_facts
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE 
        @batch_id       UNIQUEIDENTIFIER = NEWID(),
        @run_id         INT,
        @row_count      INT;

    PRINT '================================================================';
    PRINT 'GOLD FACT TABLE LOAD — Batch: ' + CAST(@batch_id AS NVARCHAR(50));
    PRINT '================================================================';

    -- ==================================================================
    -- 1. fact_loan_application
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'gold.load_facts',
            @layer = 'gold', @table_name = 'fact_loan_application',
            @batch_id = @batch_id, @run_id = @run_id OUTPUT;

        PRINT '>> Loading: gold.fact_loan_application';

        TRUNCATE TABLE gold.fact_loan_application;

        INSERT INTO gold.fact_loan_application (
            customer_key, time_key, region_key, income_key,
            customer_id, default_flag, contract_type,
            income_total, credit_amount, annuity_amount, goods_price,
            credit_income_ratio, annuity_income_ratio, goods_credit_ratio,
            employment_years,
            ext_source_1, ext_source_2, ext_source_3,
            composite_risk_score, risk_segment,
            req_credit_bureau_hour, req_credit_bureau_day,
            req_credit_bureau_week, req_credit_bureau_month,
            req_credit_bureau_quarter, req_credit_bureau_year
        )
        SELECT
            -- Dimension Lookups
            dc.customer_key,
            dt.time_key,
            dr.region_key,
            di.income_key,

            -- Business Key
            s.sk_id_curr,
            s.target,
            s.contract_type,

            -- Financial Measures
            s.income_total,
            s.credit_amount,
            s.annuity_amount,
            s.goods_price,

            -- Derived Ratios
            s.credit_income_ratio,
            s.annuity_income_ratio,
            s.goods_credit_ratio,

            -- Employment
            s.employment_years,

            -- External Scores
            s.ext_source_1,
            s.ext_source_2,
            s.ext_source_3,

            -- Composite Risk Score
            dc.composite_risk_score,

            -- Enterprise Risk Segmentation (Weighted Multi-Factor)
            CASE
                -- Critical Risk: Confirmed default
                WHEN s.target = 1 THEN 'Critical'
                -- High Risk: Multiple risk factors
                WHEN dc.composite_risk_score < 0.3 THEN 'High'
                WHEN s.credit_income_ratio >= 8 THEN 'High'
                WHEN s.annuity_income_ratio >= 0.5 THEN 'High'
                -- Medium Risk: Some risk indicators
                WHEN dc.composite_risk_score < 0.5 THEN 'Medium'
                WHEN s.credit_income_ratio >= 4 THEN 'Medium'
                WHEN s.annuity_income_ratio >= 0.3 THEN 'Medium'
                -- Low Risk: Healthy profile
                ELSE 'Low'
            END,

            -- Bureau Activity
            s.req_credit_bureau_hour,
            s.req_credit_bureau_day,
            s.req_credit_bureau_week,
            s.req_credit_bureau_month,
            s.req_credit_bureau_quarter,
            s.req_credit_bureau_year

        FROM silver.application_train s

        -- Surrogate Key Lookups
        INNER JOIN gold.dim_customer dc
            ON s.sk_id_curr = dc.customer_id
           AND dc.is_current = 1

        LEFT JOIN gold.dim_time dt
            ON dt.time_key = CAST(FORMAT(s.dwh_load_date, 'yyyyMMdd') AS INT)

        LEFT JOIN gold.dim_region dr
            ON s.region_rating_client = dr.region_rating
           AND s.region_rating_client_w_city = dr.city_rating

        LEFT JOIN gold.dim_income di
            ON s.income_total >= di.income_min
           AND s.income_total < di.income_max;

        SET @row_count = @@ROWCOUNT;
        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        PRINT '   Rows: ' + CAST(@row_count AS NVARCHAR);

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 2. fact_payment_behavior
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'gold.load_facts',
            @layer = 'gold', @table_name = 'fact_payment_behavior',
            @batch_id = @batch_id, @run_id = @run_id OUTPUT;

        PRINT '>> Loading: gold.fact_payment_behavior';

        TRUNCATE TABLE gold.fact_payment_behavior;

        INSERT INTO gold.fact_payment_behavior (
            customer_key, customer_id,
            total_installments, late_payment_count, underpaid_count, on_time_payment_count,
            avg_payment_delay_days, max_payment_delay_days, min_payment_delay_days,
            avg_payment_difference, total_payment_amount, total_instalment_amount,
            payment_completion_ratio, late_payment_ratio, underpaid_ratio,
            payment_health_score
        )
        SELECT
            dc.customer_key,
            ip.sk_id_curr,

            COUNT(*)                                                    AS total_installments,
            SUM(CASE WHEN ip.late_payment_flag = 1 THEN 1 ELSE 0 END)  AS late_payment_count,
            SUM(CASE WHEN ip.underpaid_flag = 1 THEN 1 ELSE 0 END)     AS underpaid_count,
            SUM(CASE WHEN ip.late_payment_flag = 0 AND ip.underpaid_flag = 0 THEN 1 ELSE 0 END) AS on_time_payment_count,

            AVG(ip.payment_delay_days)                                  AS avg_payment_delay_days,
            MAX(ip.payment_delay_days)                                  AS max_payment_delay_days,
            MIN(ip.payment_delay_days)                                  AS min_payment_delay_days,

            AVG(ip.payment_difference)                                  AS avg_payment_difference,
            SUM(ip.payment_amount)                                      AS total_payment_amount,
            SUM(ip.instalment_amount)                                   AS total_instalment_amount,

            CASE
                WHEN SUM(ip.instalment_amount) > 0
                THEN SUM(ip.payment_amount) / SUM(ip.instalment_amount)
                ELSE NULL
            END AS payment_completion_ratio,

            CASE
                WHEN COUNT(*) > 0
                THEN CAST(SUM(CASE WHEN ip.late_payment_flag = 1 THEN 1 ELSE 0 END) AS DECIMAL(10,4)) / COUNT(*)
                ELSE NULL
            END AS late_payment_ratio,

            CASE
                WHEN COUNT(*) > 0
                THEN CAST(SUM(CASE WHEN ip.underpaid_flag = 1 THEN 1 ELSE 0 END) AS DECIMAL(10,4)) / COUNT(*)
                ELSE NULL
            END AS underpaid_ratio,

            -- Payment Health Score (0-100, higher = better payer)
            CASE
                WHEN COUNT(*) > 0
                THEN CAST(
                    (1.0 - (
                        CAST(SUM(CASE WHEN ip.late_payment_flag = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 0.5 +
                        CAST(SUM(CASE WHEN ip.underpaid_flag = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 0.5
                    )) * 100 AS DECIMAL(5,2)
                )
                ELSE NULL
            END AS payment_health_score

        FROM silver.installments_payments ip
        INNER JOIN gold.dim_customer dc
            ON ip.sk_id_curr = dc.customer_id
           AND dc.is_current = 1
        GROUP BY dc.customer_key, ip.sk_id_curr;

        SET @row_count = @@ROWCOUNT;
        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        PRINT '   Rows: ' + CAST(@row_count AS NVARCHAR);

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 3. fact_credit_history
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'gold.load_facts',
            @layer = 'gold', @table_name = 'fact_credit_history',
            @batch_id = @batch_id, @run_id = @run_id OUTPUT;

        PRINT '>> Loading: gold.fact_credit_history';

        TRUNCATE TABLE gold.fact_credit_history;

        INSERT INTO gold.fact_credit_history (
            customer_key, customer_id,
            total_bureau_records, active_credit_count, closed_credit_count, overdue_credit_count,
            total_credit_sum, total_credit_debt, total_credit_overdue, total_credit_limit,
            avg_credit_debt_ratio, credit_utilization, overdue_ratio,
            credit_health_score
        )
        SELECT
            dc.customer_key,
            b.sk_id_curr,

            COUNT(*)                                                        AS total_bureau_records,
            SUM(CASE WHEN b.credit_active = 'Active' THEN 1 ELSE 0 END)    AS active_credit_count,
            SUM(CASE WHEN b.credit_active = 'Closed' THEN 1 ELSE 0 END)    AS closed_credit_count,
            SUM(CASE WHEN b.overdue_flag = 1 THEN 1 ELSE 0 END)            AS overdue_credit_count,

            SUM(b.credit_sum)                                               AS total_credit_sum,
            SUM(b.credit_sum_debt)                                          AS total_credit_debt,
            SUM(b.credit_sum_overdue)                                       AS total_credit_overdue,
            SUM(b.credit_sum_limit)                                         AS total_credit_limit,

            AVG(b.credit_debt_ratio)                                        AS avg_credit_debt_ratio,

            CASE
                WHEN SUM(b.credit_sum) > 0
                THEN SUM(b.credit_sum_debt) / SUM(b.credit_sum)
                ELSE NULL
            END AS credit_utilization,

            CASE
                WHEN COUNT(*) > 0
                THEN CAST(SUM(CASE WHEN b.overdue_flag = 1 THEN 1 ELSE 0 END) AS DECIMAL(10,4)) / COUNT(*)
                ELSE NULL
            END AS overdue_ratio,

            -- Credit Health Score (0-100, higher = better credit history)
            CASE
                WHEN COUNT(*) > 0
                THEN CAST(
                    (1.0 - (
                        CAST(SUM(CASE WHEN b.overdue_flag = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 0.6 +
                        CASE WHEN SUM(b.credit_sum) > 0 
                            THEN LEAST(SUM(b.credit_sum_debt) / SUM(b.credit_sum), 1.0) * 0.4
                            ELSE 0 
                        END
                    )) * 100 AS DECIMAL(5,2)
                )
                ELSE NULL
            END AS credit_health_score

        FROM silver.bureau b
        INNER JOIN gold.dim_customer dc
            ON b.sk_id_curr = dc.customer_id
           AND dc.is_current = 1
        GROUP BY dc.customer_key, b.sk_id_curr;

        SET @row_count = @@ROWCOUNT;
        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        PRINT '   Rows: ' + CAST(@row_count AS NVARCHAR);

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    -- ==================================================================
    -- 4. fact_default_events
    -- ==================================================================
    BEGIN TRY

        EXEC audit.sp_log_etl_start 
            @procedure_name = 'gold.load_facts',
            @layer = 'gold', @table_name = 'fact_default_events',
            @batch_id = @batch_id, @run_id = @run_id OUTPUT;

        PRINT '>> Loading: gold.fact_default_events';

        TRUNCATE TABLE gold.fact_default_events;

        INSERT INTO gold.fact_default_events (
            customer_key, time_key, region_key, income_key,
            customer_id, default_flag,
            credit_amount, outstanding_balance, annuity_amount,
            income_total, goods_price,
            credit_income_ratio, annuity_income_ratio, composite_risk_score,
            age_years, employment_years, gender, education_type, income_type,
            active_credits_at_default, overdue_credits_at_default,
            late_payments_at_default, payment_completion_ratio,
            risk_segment
        )
        SELECT
            dc.customer_key,
            dt.time_key,
            dr.region_key,
            di.income_key,

            s.sk_id_curr,
            1,  -- default_flag

            s.credit_amount,
            s.credit_amount,  -- Outstanding ≈ credit amount at default
            s.annuity_amount,
            s.income_total,
            s.goods_price,

            s.credit_income_ratio,
            s.annuity_income_ratio,
            dc.composite_risk_score,

            s.age_years,
            s.employment_years,
            s.gender,
            s.education_type,
            s.income_type,

            ISNULL(ch.active_credit_count, 0),
            ISNULL(ch.overdue_credit_count, 0),
            ISNULL(pb.late_payment_count, 0),
            pb.payment_completion_ratio,

            CASE
                WHEN dc.composite_risk_score < 0.3 THEN 'Critical'
                WHEN dc.composite_risk_score < 0.5 THEN 'High'
                WHEN dc.composite_risk_score < 0.7 THEN 'Medium'
                ELSE 'Low'
            END

        FROM silver.application_train s

        INNER JOIN gold.dim_customer dc
            ON s.sk_id_curr = dc.customer_id AND dc.is_current = 1

        LEFT JOIN gold.dim_time dt
            ON dt.time_key = CAST(FORMAT(s.dwh_load_date, 'yyyyMMdd') AS INT)

        LEFT JOIN gold.dim_region dr
            ON s.region_rating_client = dr.region_rating
           AND s.region_rating_client_w_city = dr.city_rating

        LEFT JOIN gold.dim_income di
            ON s.income_total >= di.income_min AND s.income_total < di.income_max

        LEFT JOIN gold.fact_credit_history ch
            ON dc.customer_key = ch.customer_key

        LEFT JOIN gold.fact_payment_behavior pb
            ON dc.customer_key = pb.customer_key

        WHERE s.target = 1;  -- Only default events

        SET @row_count = @@ROWCOUNT;
        EXEC audit.sp_log_etl_end @run_id = @run_id, @status = 'SUCCESS', @rows_affected = @row_count;
        PRINT '   Rows: ' + CAST(@row_count AS NVARCHAR);

    END TRY
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        PRINT '   ERROR: ' + ERROR_MESSAGE();
    END CATCH;

    PRINT '================================================================';
    PRINT 'GOLD FACT TABLE LOAD COMPLETED';
    PRINT '================================================================';

END;
GO
