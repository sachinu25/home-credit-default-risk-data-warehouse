USE DataWarehouse;
GO

/*
===============================================================================
DDL Script: Gold Reports / Analytical Marts
===============================================================================
Purpose:
    Enterprise reporting views combining dimensions and facts for
    Power BI and executive dashboarding.

Report Views:
    1. gold.report_customer_risk_summary   — Executive risk dashboard
    2. gold.report_portfolio_overview       — Portfolio-level KPIs
    3. gold.report_default_analysis         — Default event deep-dive
    4. gold.report_data_quality_dashboard   — DQ monitoring view

Author:     Anumodit Shukla
Created:    2025
Modified:   2026 — Enterprise reporting layer
===============================================================================
*/

DROP VIEW IF EXISTS gold.report_customer_risk_summary;
DROP VIEW IF EXISTS gold.report_portfolio_overview;
DROP VIEW IF EXISTS gold.report_default_analysis;
DROP VIEW IF EXISTS gold.report_data_quality_dashboard;
GO

/*
===============================================================================
Report 1: Customer Risk Summary
===============================================================================
Purpose:
    Master customer-level risk mart combining all dimensions and facts.
    Primary data source for the Power BI Executive Dashboard.

Grain: 1 row = 1 customer
===============================================================================
*/

CREATE VIEW gold.report_customer_risk_summary AS

SELECT
    -- Customer Dimension
    c.customer_key,
    c.customer_id,
    c.gender,
    c.age_years,
    c.age_band,
    c.education_type,
    c.family_status,
    c.income_type,
    c.occupation_type,
    c.housing_type,
    c.owns_car,
    c.owns_realty,
    c.composite_risk_score,

    -- Region Dimension
    r.region_tier,
    r.risk_classification   AS region_risk,

    -- Income Dimension
    i.income_band,
    i.income_percentile,

    -- Loan Application Fact
    l.default_flag,
    l.contract_type,
    l.income_total,
    l.credit_amount,
    l.annuity_amount,
    l.goods_price,
    l.credit_income_ratio,
    l.annuity_income_ratio,
    l.goods_credit_ratio,
    l.risk_segment,

    -- Payment Behavior Fact
    ISNULL(p.total_installments, 0)     AS total_installments,
    ISNULL(p.late_payment_count, 0)     AS late_payment_count,
    ISNULL(p.underpaid_count, 0)        AS underpaid_count,
    ISNULL(p.on_time_payment_count, 0)  AS on_time_payment_count,
    p.avg_payment_delay_days,
    p.payment_completion_ratio,
    p.late_payment_ratio,
    p.payment_health_score,

    -- Credit History Fact
    ISNULL(b.total_bureau_records, 0)   AS total_bureau_records,
    ISNULL(b.active_credit_count, 0)    AS active_credit_count,
    ISNULL(b.overdue_credit_count, 0)   AS overdue_credit_count,
    b.total_credit_sum,
    b.total_credit_debt,
    b.total_credit_overdue,
    b.credit_utilization,
    b.credit_health_score,

    -- Metadata
    GETDATE() AS report_generated_date

FROM gold.dim_customer c

LEFT JOIN gold.fact_loan_application l
    ON c.customer_key = l.customer_key

LEFT JOIN gold.fact_payment_behavior p
    ON c.customer_key = p.customer_key

LEFT JOIN gold.fact_credit_history b
    ON c.customer_key = b.customer_key

LEFT JOIN gold.dim_region r
    ON l.region_key = r.region_key

LEFT JOIN gold.dim_income i
    ON l.income_key = i.income_key

WHERE c.is_current = 1;
GO

/*
===============================================================================
Report 2: Portfolio Overview
===============================================================================
Purpose:
    Portfolio-level aggregated KPIs for executive dashboard.
    Single row summary of the entire loan portfolio.
===============================================================================
*/

CREATE VIEW gold.report_portfolio_overview AS

SELECT
    COUNT(DISTINCT l.customer_id)                                       AS total_customers,
    COUNT(*)                                                            AS total_applications,
    SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END)                AS total_defaults,
    CAST(
        SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    )                                                                   AS default_rate_pct,

    SUM(l.credit_amount)                                                AS total_portfolio_exposure,
    AVG(l.income_total)                                                 AS avg_customer_income,
    AVG(l.credit_amount)                                                AS avg_credit_amount,
    AVG(l.annuity_amount)                                               AS avg_annuity_amount,
    AVG(l.credit_income_ratio)                                          AS avg_credit_income_ratio,
    AVG(l.composite_risk_score)                                         AS avg_risk_score,

    -- Risk Segment Distribution
    SUM(CASE WHEN l.risk_segment = 'Low' THEN 1 ELSE 0 END)            AS low_risk_count,
    SUM(CASE WHEN l.risk_segment = 'Medium' THEN 1 ELSE 0 END)         AS medium_risk_count,
    SUM(CASE WHEN l.risk_segment = 'High' THEN 1 ELSE 0 END)           AS high_risk_count,
    SUM(CASE WHEN l.risk_segment = 'Critical' THEN 1 ELSE 0 END)       AS critical_risk_count,

    -- Exposure by Segment
    SUM(CASE WHEN l.risk_segment = 'Critical' THEN l.credit_amount ELSE 0 END) AS critical_exposure,
    SUM(CASE WHEN l.risk_segment = 'High' THEN l.credit_amount ELSE 0 END)     AS high_risk_exposure,

    GETDATE() AS report_date

FROM gold.fact_loan_application l;
GO

/*
===============================================================================
Report 3: Default Analysis
===============================================================================
Purpose:
    Detailed default event analysis for risk management.
===============================================================================
*/

CREATE VIEW gold.report_default_analysis AS

SELECT
    d.customer_id,
    d.gender,
    d.age_years,
    d.education_type,
    d.income_type,

    d.credit_amount,
    d.income_total,
    d.credit_income_ratio,
    d.annuity_income_ratio,
    d.composite_risk_score,

    d.active_credits_at_default,
    d.overdue_credits_at_default,
    d.late_payments_at_default,
    d.payment_completion_ratio,
    d.risk_segment,

    i.income_band,
    r.region_tier,

    d.dwh_load_date

FROM gold.fact_default_events d

LEFT JOIN gold.dim_income i
    ON d.income_key = i.income_key

LEFT JOIN gold.dim_region r
    ON d.region_key = r.region_key;
GO

/*
===============================================================================
Report 4: Data Quality Dashboard
===============================================================================
Purpose:
    View over audit.data_quality_log for Power BI DQ monitoring page.
===============================================================================
*/

CREATE VIEW gold.report_data_quality_dashboard AS

SELECT
    check_id,
    batch_id,
    check_name,
    layer,
    table_name,
    check_type,
    result_status,
    records_affected,
    threshold,
    details,
    check_timestamp,

    CASE result_status
        WHEN 'PASS' THEN 1
        WHEN 'WARN' THEN 0
        WHEN 'FAIL' THEN 0
        ELSE 0
    END AS is_passed,

    CAST(check_timestamp AS DATE) AS check_date

FROM audit.data_quality_log;
GO

PRINT '================================================================';
PRINT 'Gold Report Views Created Successfully';
PRINT '  - gold.report_customer_risk_summary';
PRINT '  - gold.report_portfolio_overview';
PRINT '  - gold.report_default_analysis';
PRINT '  - gold.report_data_quality_dashboard';
PRINT '================================================================';
GO