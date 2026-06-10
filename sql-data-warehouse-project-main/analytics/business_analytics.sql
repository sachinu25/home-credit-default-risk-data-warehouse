USE DataWarehouse;
GO

/*
===============================================================================
Business Analytics — Advanced SQL Analysis Suite
===============================================================================
Purpose:
    Production-ready analytical queries demonstrating advanced SQL skills
    for credit risk analysis across the Home Credit portfolio.

SQL Skills Demonstrated:
    ✓ Common Table Expressions (CTE)
    ✓ Window Functions: ROW_NUMBER, RANK, DENSE_RANK, NTILE
    ✓ LAG / LEAD for trend analysis
    ✓ Running Totals (SUM OVER ORDER BY)
    ✓ Moving Averages (AVG OVER ROWS BETWEEN)
    ✓ CASE-based business segmentation
    ✓ Conditional aggregation
    ✓ Subqueries and correlated queries
    ✓ Complex JOINs across star schema

Dataset:
    Home Credit Default Risk — 307K applications, 60M+ records

Author:     Anumodit Shukla
===============================================================================
*/

-- ============================================================================
-- 1. TOP HIGH-RISK CUSTOMERS WITH RANKING
-- Skills: CTE, ROW_NUMBER, CASE, Multi-table JOIN
-- Business: Identify top 20 riskiest customers for watchlist
-- ============================================================================

WITH customer_risk AS (
    SELECT
        c.customer_id,
        c.gender,
        c.age_years,
        c.age_band,
        c.income_type,
        c.education_type,
        l.income_total,
        l.credit_amount,
        l.credit_income_ratio,
        l.annuity_income_ratio,
        l.default_flag,
        l.risk_segment,
        ISNULL(p.late_payment_count, 0)     AS late_payments,
        ISNULL(p.payment_completion_ratio, 1) AS payment_ratio,
        ISNULL(b.overdue_credit_count, 0)   AS overdue_credits,
        ISNULL(b.total_credit_debt, 0)      AS total_debt,

        -- Composite Risk Score: weighted combination of risk factors
        (
            CASE WHEN l.default_flag = 1 THEN 40 ELSE 0 END +
            CASE WHEN l.credit_income_ratio > 5 THEN 15 ELSE
                 CASE WHEN l.credit_income_ratio > 3 THEN 8 ELSE 0 END
            END +
            CASE WHEN ISNULL(p.late_payment_count, 0) > 5 THEN 15 ELSE
                 CASE WHEN ISNULL(p.late_payment_count, 0) > 2 THEN 8 ELSE 0 END
            END +
            CASE WHEN ISNULL(b.overdue_credit_count, 0) > 3 THEN 15 ELSE
                 CASE WHEN ISNULL(b.overdue_credit_count, 0) > 1 THEN 8 ELSE 0 END
            END +
            CASE WHEN l.annuity_income_ratio > 0.5 THEN 15 ELSE
                 CASE WHEN l.annuity_income_ratio > 0.3 THEN 8 ELSE 0 END
            END
        ) AS risk_score

    FROM gold.dim_customer c
    INNER JOIN gold.fact_loan_application l ON c.customer_key = l.customer_key
    LEFT JOIN gold.fact_payment_behavior p  ON c.customer_key = p.customer_key
    LEFT JOIN gold.fact_credit_history b    ON c.customer_key = b.customer_key
    WHERE c.is_current = 1
),
ranked_customers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY risk_score DESC) AS risk_rank
    FROM customer_risk
)
SELECT
    risk_rank,
    customer_id,
    gender,
    age_band,
    income_type,
    income_total,
    credit_amount,
    credit_income_ratio,
    late_payments,
    overdue_credits,
    risk_score,
    risk_segment
FROM ranked_customers
WHERE risk_rank <= 20
ORDER BY risk_rank;
GO

-- ============================================================================
-- 2. CUSTOMER RISK RANKING BY INCOME BAND
-- Skills: RANK, DENSE_RANK, GROUP BY, Conditional Aggregation
-- Business: Compare default rates across income segments
-- ============================================================================

WITH income_analysis AS (
    SELECT
        i.income_band,
        i.band_order,
        COUNT(*)                                                    AS total_customers,
        SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END)        AS default_count,
        CAST(
            SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
            AS DECIMAL(10,2)
        )                                                           AS default_rate_pct,
        AVG(l.credit_amount)                                        AS avg_credit,
        AVG(l.credit_income_ratio)                                  AS avg_credit_income_ratio
    FROM gold.fact_loan_application l
    INNER JOIN gold.dim_income i ON l.income_key = i.income_key
    GROUP BY i.income_band, i.band_order
)
SELECT
    income_band,
    total_customers,
    default_count,
    default_rate_pct,
    avg_credit,
    avg_credit_income_ratio,
    RANK() OVER (ORDER BY default_rate_pct DESC)        AS risk_rank,
    DENSE_RANK() OVER (ORDER BY default_rate_pct DESC)  AS risk_dense_rank
FROM income_analysis
ORDER BY band_order;
GO

-- ============================================================================
-- 3. DEFAULT RATE BY AGE GROUP
-- Skills: CTE, CASE segmentation, Percentage calculation
-- Business: Identify which age demographics carry highest default risk
-- ============================================================================

WITH age_defaults AS (
    SELECT
        c.age_band,
        COUNT(*)                                                AS total_customers,
        SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END)    AS defaulters,
        SUM(CASE WHEN l.default_flag = 0 THEN 1 ELSE 0 END)    AS non_defaulters,
        AVG(l.income_total)                                     AS avg_income,
        AVG(l.credit_amount)                                    AS avg_credit
    FROM gold.dim_customer c
    INNER JOIN gold.fact_loan_application l ON c.customer_key = l.customer_key
    WHERE c.is_current = 1
    GROUP BY c.age_band
)
SELECT
    age_band,
    total_customers,
    defaulters,
    non_defaulters,
    CAST(defaulters * 100.0 / total_customers AS DECIMAL(10,2)) AS default_rate_pct,
    avg_income,
    avg_credit,
    RANK() OVER (ORDER BY CAST(defaulters * 100.0 / total_customers AS DECIMAL(10,2)) DESC) AS risk_rank
FROM age_defaults
ORDER BY risk_rank;
GO

-- ============================================================================
-- 4. RISK DECILE ANALYSIS (NTILE)
-- Skills: NTILE(10), CTE, Aggregation by percentile
-- Business: Segment portfolio into 10 equal risk buckets for Basel reporting
-- ============================================================================

WITH customer_deciles AS (
    SELECT
        l.customer_id,
        l.credit_amount,
        l.income_total,
        l.credit_income_ratio,
        l.default_flag,
        c.composite_risk_score,
        NTILE(10) OVER (ORDER BY c.composite_risk_score ASC) AS risk_decile
    FROM gold.fact_loan_application l
    INNER JOIN gold.dim_customer c ON l.customer_key = c.customer_key
    WHERE c.is_current = 1
      AND c.composite_risk_score IS NOT NULL
)
SELECT
    risk_decile,
    COUNT(*)                                                    AS customers,
    SUM(CASE WHEN default_flag = 1 THEN 1 ELSE 0 END)          AS defaults,
    CAST(
        SUM(CASE WHEN default_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    )                                                           AS default_rate_pct,
    AVG(composite_risk_score)                                   AS avg_risk_score,
    AVG(credit_income_ratio)                                    AS avg_credit_income_ratio,
    SUM(credit_amount)                                          AS total_exposure,
    AVG(credit_amount)                                          AS avg_credit
FROM customer_deciles
GROUP BY risk_decile
ORDER BY risk_decile;
GO

-- ============================================================================
-- 5. PAYMENT TREND ANALYSIS — LAG/LEAD
-- Skills: LAG, LEAD, CTE, Period-over-period comparison
-- Business: Detect payment behavior deterioration or improvement
-- ============================================================================

WITH payment_by_installment AS (
    SELECT
        sk_id_curr                                          AS customer_id,
        installment_number,
        instalment_amount,
        payment_amount,
        payment_delay_days,
        late_payment_flag,
        LAG(payment_amount, 1) OVER (
            PARTITION BY sk_id_curr ORDER BY installment_number
        )                                                   AS prev_payment,
        LEAD(payment_amount, 1) OVER (
            PARTITION BY sk_id_curr ORDER BY installment_number
        )                                                   AS next_payment,
        LAG(payment_delay_days, 1) OVER (
            PARTITION BY sk_id_curr ORDER BY installment_number
        )                                                   AS prev_delay
    FROM silver.installments_payments
    WHERE sk_id_curr IN (
        SELECT TOP 100 sk_id_curr
        FROM silver.installments_payments
        GROUP BY sk_id_curr
        HAVING COUNT(*) >= 10
        ORDER BY sk_id_curr
    )
)
SELECT
    customer_id,
    installment_number,
    payment_amount,
    prev_payment,
    next_payment,
    payment_delay_days,
    prev_delay,

    -- Payment trend indicator
    CASE
        WHEN payment_amount > ISNULL(prev_payment, payment_amount)
            THEN 'Increasing'
        WHEN payment_amount < ISNULL(prev_payment, payment_amount)
            THEN 'Decreasing'
        ELSE 'Stable'
    END AS payment_trend,

    -- Delay trend indicator
    CASE
        WHEN payment_delay_days > ISNULL(prev_delay, 0) THEN 'Worsening'
        WHEN payment_delay_days < ISNULL(prev_delay, 0) THEN 'Improving'
        ELSE 'Stable'
    END AS delay_trend

FROM payment_by_installment
ORDER BY customer_id, installment_number;
GO

-- ============================================================================
-- 6. RUNNING TOTAL OF CREDIT EXPOSURE
-- Skills: SUM() OVER (ORDER BY), Running total, Cumulative analysis
-- Business: Track portfolio exposure accumulation for risk monitoring
-- ============================================================================

WITH ordered_loans AS (
    SELECT
        l.customer_id,
        c.age_band,
        l.credit_amount,
        l.income_total,
        l.default_flag,

        ROW_NUMBER() OVER (ORDER BY l.credit_amount DESC)   AS loan_rank,

        SUM(l.credit_amount) OVER (
            ORDER BY l.credit_amount DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                   AS running_total_exposure,

        SUM(l.credit_amount) OVER ()                        AS total_portfolio_exposure

    FROM gold.fact_loan_application l
    INNER JOIN gold.dim_customer c ON l.customer_key = c.customer_key
    WHERE c.is_current = 1
)
SELECT TOP 50
    loan_rank,
    customer_id,
    age_band,
    credit_amount,
    running_total_exposure,
    total_portfolio_exposure,
    CAST(
        running_total_exposure * 100.0 / total_portfolio_exposure
        AS DECIMAL(10,2)
    )                                                       AS cumulative_pct,
    default_flag
FROM ordered_loans
ORDER BY loan_rank;
GO

-- ============================================================================
-- 7. DEFAULT RATE BY REGION
-- Skills: CTE, JOIN, Conditional aggregation, RANK
-- Business: Geographic risk distribution for portfolio diversification
-- ============================================================================

WITH region_defaults AS (
    SELECT
        r.region_tier,
        r.risk_classification,
        COUNT(*)                                                AS total_customers,
        SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END)    AS defaulters,
        AVG(l.credit_amount)                                    AS avg_credit,
        SUM(l.credit_amount)                                    AS total_exposure
    FROM gold.fact_loan_application l
    INNER JOIN gold.dim_region r ON l.region_key = r.region_key
    GROUP BY r.region_tier, r.risk_classification
)
SELECT
    region_tier,
    risk_classification,
    total_customers,
    defaulters,
    CAST(defaulters * 100.0 / total_customers AS DECIMAL(10,2)) AS default_rate_pct,
    avg_credit,
    total_exposure,
    RANK() OVER (ORDER BY CAST(defaulters * 100.0 / total_customers AS DECIMAL(10,2)) DESC) AS risk_rank
FROM region_defaults
ORDER BY risk_rank;
GO

-- ============================================================================
-- 8. HIGH-RISK OCCUPATION ANALYSIS
-- Skills: CTE, RANK, HAVING, Conditional aggregation
-- Business: Identify occupations with highest default concentration
-- ============================================================================

WITH occupation_risk AS (
    SELECT
        c.occupation_type,
        COUNT(*)                                                AS total_customers,
        SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END)    AS defaulters,
        AVG(l.income_total)                                     AS avg_income,
        AVG(l.credit_amount)                                    AS avg_credit,
        AVG(l.credit_income_ratio)                              AS avg_ratio
    FROM gold.dim_customer c
    INNER JOIN gold.fact_loan_application l ON c.customer_key = l.customer_key
    WHERE c.is_current = 1
      AND c.occupation_type IS NOT NULL
    GROUP BY c.occupation_type
    HAVING COUNT(*) >= 100  -- Minimum sample size for statistical significance
)
SELECT
    occupation_type,
    total_customers,
    defaulters,
    CAST(defaulters * 100.0 / total_customers AS DECIMAL(10,2)) AS default_rate_pct,
    avg_income,
    avg_credit,
    avg_ratio,
    RANK() OVER (ORDER BY CAST(defaulters * 100.0 / total_customers AS DECIMAL(10,2)) DESC) AS risk_rank
FROM occupation_risk
ORDER BY risk_rank;
GO

-- ============================================================================
-- 9. CUSTOMER SEGMENTATION (RFM-Style)
-- Skills: NTILE (3 dimensions), CTE, Multi-factor segmentation
-- Business: Segment customers by recency, credit, and payment behavior
-- ============================================================================

WITH customer_scores AS (
    SELECT
        c.customer_id,
        c.gender,
        c.age_band,

        l.credit_amount,
        l.income_total,
        l.default_flag,

        ISNULL(p.payment_completion_ratio, 0)               AS payment_ratio,
        ISNULL(p.late_payment_count, 0)                     AS late_payments,
        ISNULL(b.total_bureau_records, 0)                   AS bureau_records,

        -- Segment by credit amount (1=Low, 4=High)
        NTILE(4) OVER (ORDER BY l.credit_amount)            AS credit_quartile,

        -- Segment by income (1=Low, 4=High)
        NTILE(4) OVER (ORDER BY l.income_total)             AS income_quartile,

        -- Segment by payment reliability (1=Best, 4=Worst)
        NTILE(4) OVER (
            ORDER BY ISNULL(p.payment_completion_ratio, 0) DESC
        )                                                   AS payment_quartile

    FROM gold.dim_customer c
    INNER JOIN gold.fact_loan_application l ON c.customer_key = l.customer_key
    LEFT JOIN gold.fact_payment_behavior p  ON c.customer_key = p.customer_key
    LEFT JOIN gold.fact_credit_history b    ON c.customer_key = b.customer_key
    WHERE c.is_current = 1
)
SELECT
    CASE
        WHEN credit_quartile <= 2 AND income_quartile >= 3 AND payment_quartile <= 2
            THEN 'Premium Low-Risk'
        WHEN credit_quartile >= 3 AND income_quartile <= 2 AND payment_quartile >= 3
            THEN 'High-Risk Overextended'
        WHEN credit_quartile >= 3 AND income_quartile >= 3
            THEN 'High-Value Customer'
        WHEN payment_quartile >= 3 AND late_payments > 3
            THEN 'Payment-Distressed'
        ELSE 'Standard'
    END                                                     AS customer_segment,

    COUNT(*)                                                AS customer_count,
    SUM(CASE WHEN default_flag = 1 THEN 1 ELSE 0 END)      AS defaults,
    CAST(
        SUM(CASE WHEN default_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    )                                                       AS default_rate_pct,
    AVG(credit_amount)                                      AS avg_credit,
    AVG(income_total)                                       AS avg_income,
    AVG(payment_ratio)                                      AS avg_payment_ratio
FROM customer_scores
GROUP BY
    CASE
        WHEN credit_quartile <= 2 AND income_quartile >= 3 AND payment_quartile <= 2
            THEN 'Premium Low-Risk'
        WHEN credit_quartile >= 3 AND income_quartile <= 2 AND payment_quartile >= 3
            THEN 'High-Risk Overextended'
        WHEN credit_quartile >= 3 AND income_quartile >= 3
            THEN 'High-Value Customer'
        WHEN payment_quartile >= 3 AND late_payments > 3
            THEN 'Payment-Distressed'
        ELSE 'Standard'
    END
ORDER BY default_rate_pct DESC;
GO

-- ============================================================================
-- 10. CREDIT UTILIZATION ANALYSIS
-- Skills: CASE segmentation, Aggregation, Business logic
-- Business: Analyze how customers use their credit relative to limits
-- ============================================================================

WITH utilization_bands AS (
    SELECT
        sk_id_curr                                          AS customer_id,
        AVG(credit_utilization_ratio)                       AS avg_utilization,
        MAX(credit_utilization_ratio)                       AS max_utilization,
        COUNT(*)                                            AS months_observed,
        SUM(CASE WHEN dpd_flag = 1 THEN 1 ELSE 0 END)      AS months_delinquent,
        CASE
            WHEN AVG(credit_utilization_ratio) < 0.3   THEN 'Low (< 30%)'
            WHEN AVG(credit_utilization_ratio) < 0.5   THEN 'Moderate (30-50%)'
            WHEN AVG(credit_utilization_ratio) < 0.7   THEN 'High (50-70%)'
            WHEN AVG(credit_utilization_ratio) < 0.9   THEN 'Very High (70-90%)'
            ELSE 'Maxed Out (90%+)'
        END                                                 AS utilization_band
    FROM silver.credit_card_balance
    WHERE credit_utilization_ratio IS NOT NULL
    GROUP BY sk_id_curr
)
SELECT
    utilization_band,
    COUNT(*)                                                AS customer_count,
    AVG(avg_utilization)                                    AS avg_utilization_ratio,
    AVG(months_observed)                                    AS avg_months_observed,
    SUM(months_delinquent)                                  AS total_delinquent_months,
    CAST(
        SUM(months_delinquent) * 100.0 / SUM(months_observed)
        AS DECIMAL(10,2)
    )                                                       AS delinquency_rate_pct
FROM utilization_bands
GROUP BY utilization_band
ORDER BY AVG(avg_utilization);
GO

-- ============================================================================
-- 11. PORTFOLIO RISK SUMMARY KPIs
-- Skills: Subquery, Conditional aggregation, Multiple metrics
-- Business: Executive-level portfolio health dashboard
-- ============================================================================

SELECT
    -- Volume KPIs
    COUNT(*)                                                    AS total_applications,
    COUNT(DISTINCT l.customer_id)                               AS unique_customers,

    -- Default KPIs
    SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END)        AS total_defaults,
    CAST(
        SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    )                                                           AS default_rate_pct,

    -- Financial KPIs
    SUM(l.credit_amount)                                        AS total_portfolio_exposure,
    AVG(l.credit_amount)                                        AS avg_loan_size,
    AVG(l.income_total)                                         AS avg_customer_income,

    -- Exposure at Default
    SUM(CASE WHEN l.default_flag = 1 THEN l.credit_amount ELSE 0 END) AS exposure_at_default,

    -- Risk Ratio KPIs
    AVG(l.credit_income_ratio)                                  AS avg_credit_income_ratio,
    AVG(l.annuity_income_ratio)                                 AS avg_annuity_income_ratio,
    AVG(c.composite_risk_score)                                 AS avg_portfolio_risk_score,

    -- Risk Segment Distribution
    SUM(CASE WHEN l.risk_segment = 'Low' THEN 1 ELSE 0 END)    AS low_risk_count,
    SUM(CASE WHEN l.risk_segment = 'Medium' THEN 1 ELSE 0 END) AS medium_risk_count,
    SUM(CASE WHEN l.risk_segment = 'High' THEN 1 ELSE 0 END)   AS high_risk_count,
    SUM(CASE WHEN l.risk_segment = 'Critical' THEN 1 ELSE 0 END) AS critical_risk_count

FROM gold.fact_loan_application l
INNER JOIN gold.dim_customer c ON l.customer_key = c.customer_key
WHERE c.is_current = 1;
GO

-- ============================================================================
-- 12. LOAN PERFORMANCE BY CONTRACT TYPE
-- Skills: GROUP BY, Conditional aggregation, Business metrics
-- Business: Compare risk profiles across product types
-- ============================================================================

SELECT
    l.contract_type,
    COUNT(*)                                                    AS total_loans,
    SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END)        AS defaults,
    CAST(
        SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    )                                                           AS default_rate_pct,
    AVG(l.credit_amount)                                        AS avg_credit,
    AVG(l.income_total)                                         AS avg_income,
    AVG(l.credit_income_ratio)                                  AS avg_credit_income_ratio,
    SUM(l.credit_amount)                                        AS total_exposure,

    -- Concentration risk
    CAST(
        SUM(l.credit_amount) * 100.0 / SUM(SUM(l.credit_amount)) OVER ()
        AS DECIMAL(10,2)
    )                                                           AS exposure_concentration_pct
FROM gold.fact_loan_application l
GROUP BY l.contract_type
ORDER BY default_rate_pct DESC;
GO

-- ============================================================================
-- 13. GENDER-BASED RISK COMPARISON
-- Skills: CTE, Multiple aggregations, Comparative analysis
-- Business: Demographic risk profiling for underwriting models
-- ============================================================================

WITH gender_risk AS (
    SELECT
        c.gender,
        COUNT(*)                                                AS total_customers,
        SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END)    AS defaults,
        AVG(l.credit_amount)                                    AS avg_credit,
        AVG(l.income_total)                                     AS avg_income,
        AVG(l.credit_income_ratio)                              AS avg_credit_income_ratio,
        AVG(ISNULL(p.payment_completion_ratio, 0))              AS avg_payment_ratio,
        AVG(ISNULL(p.late_payment_count, 0))                    AS avg_late_payments,
        AVG(c.composite_risk_score)                             AS avg_risk_score
    FROM gold.dim_customer c
    INNER JOIN gold.fact_loan_application l ON c.customer_key = l.customer_key
    LEFT JOIN gold.fact_payment_behavior p  ON c.customer_key = p.customer_key
    WHERE c.is_current = 1
    GROUP BY c.gender
)
SELECT
    gender,
    total_customers,
    defaults,
    CAST(defaults * 100.0 / total_customers AS DECIMAL(10,2))  AS default_rate_pct,
    avg_credit,
    avg_income,
    avg_credit_income_ratio,
    avg_payment_ratio,
    avg_late_payments,
    avg_risk_score
FROM gender_risk
ORDER BY default_rate_pct DESC;
GO

-- ============================================================================
-- 14. EDUCATION-BASED DEFAULT ANALYSIS WITH RANKING
-- Skills: CTE, DENSE_RANK, Multiple metrics
-- Business: Education level impact on creditworthiness
-- ============================================================================

WITH education_analysis AS (
    SELECT
        c.education_type,
        COUNT(*)                                                AS total_customers,
        SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END)    AS defaults,
        AVG(l.income_total)                                     AS avg_income,
        AVG(l.credit_amount)                                    AS avg_credit,
        AVG(c.composite_risk_score)                             AS avg_risk_score
    FROM gold.dim_customer c
    INNER JOIN gold.fact_loan_application l ON c.customer_key = l.customer_key
    WHERE c.is_current = 1
      AND c.education_type IS NOT NULL
    GROUP BY c.education_type
)
SELECT
    education_type,
    total_customers,
    defaults,
    CAST(defaults * 100.0 / total_customers AS DECIMAL(10,2))  AS default_rate_pct,
    avg_income,
    avg_credit,
    avg_risk_score,
    DENSE_RANK() OVER (ORDER BY CAST(defaults * 100.0 / total_customers AS DECIMAL(10,2)) DESC) AS risk_rank
FROM education_analysis
ORDER BY risk_rank;
GO

-- ============================================================================
-- 15. MOVING AVERAGE — PAYMENT BEHAVIOR TREND
-- Skills: AVG() OVER (ROWS BETWEEN), Moving average, Trend detection
-- Business: Detect 3-installment rolling payment patterns
-- ============================================================================

WITH payment_series AS (
    SELECT
        sk_id_curr                  AS customer_id,
        installment_number,
        payment_amount,
        instalment_amount,
        payment_delay_days,

        AVG(payment_amount) OVER (
            PARTITION BY sk_id_curr
            ORDER BY installment_number
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )                           AS moving_avg_payment_3,

        AVG(payment_delay_days) OVER (
            PARTITION BY sk_id_curr
            ORDER BY installment_number
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )                           AS moving_avg_delay_3,

        SUM(payment_amount) OVER (
            PARTITION BY sk_id_curr
            ORDER BY installment_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                           AS cumulative_payments

    FROM silver.installments_payments
    WHERE sk_id_curr IN (
        SELECT TOP 50 sk_id_curr
        FROM silver.installments_payments
        GROUP BY sk_id_curr
        HAVING COUNT(*) >= 12
        ORDER BY sk_id_curr
    )
)
SELECT
    customer_id,
    installment_number,
    payment_amount,
    moving_avg_payment_3,
    payment_delay_days,
    moving_avg_delay_3,
    cumulative_payments,

    CASE
        WHEN payment_amount > moving_avg_payment_3 * 1.1 THEN 'Above Trend'
        WHEN payment_amount < moving_avg_payment_3 * 0.9 THEN 'Below Trend'
        ELSE 'On Trend'
    END AS payment_vs_trend

FROM payment_series
ORDER BY customer_id, installment_number;
GO

-- ============================================================================
-- 16. RISK DISTRIBUTION — HISTOGRAM ANALYSIS
-- Skills: CTE, NTILE, COUNT distribution
-- Business: Risk score distribution shape for regulatory reporting
-- ============================================================================

WITH score_buckets AS (
    SELECT
        c.customer_id,
        c.composite_risk_score,
        NTILE(20) OVER (ORDER BY c.composite_risk_score) AS score_bucket
    FROM gold.dim_customer c
    WHERE c.is_current = 1
      AND c.composite_risk_score IS NOT NULL
)
SELECT
    score_bucket,
    COUNT(*)                                    AS customer_count,
    MIN(composite_risk_score)                   AS bucket_min_score,
    MAX(composite_risk_score)                   AS bucket_max_score,
    AVG(composite_risk_score)                   AS bucket_avg_score,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    )                                           AS pct_of_portfolio
FROM score_buckets
GROUP BY score_bucket
ORDER BY score_bucket;
GO

-- ============================================================================
-- 17. HOUSING TYPE vs DEFAULT — ASSET OWNERSHIP IMPACT
-- Skills: Conditional aggregation, Multiple CASE, Business insight
-- Business: Does property ownership reduce default risk?
-- ============================================================================

SELECT
    c.housing_type,
    c.owns_car,
    c.owns_realty,
    COUNT(*)                                                AS total_customers,
    SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END)    AS defaults,
    CAST(
        SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    )                                                       AS default_rate_pct,
    AVG(l.income_total)                                     AS avg_income,
    AVG(l.credit_amount)                                    AS avg_credit,
    RANK() OVER (
        ORDER BY CAST(
            SUM(CASE WHEN l.default_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
            AS DECIMAL(10,2)
        ) DESC
    )                                                       AS risk_rank
FROM gold.dim_customer c
INNER JOIN gold.fact_loan_application l ON c.customer_key = l.customer_key
WHERE c.is_current = 1
GROUP BY c.housing_type, c.owns_car, c.owns_realty
HAVING COUNT(*) >= 50
ORDER BY default_rate_pct DESC;
GO

PRINT '================================================================';
PRINT 'Business Analytics Execution Complete';
PRINT '17 Analytical Queries | Home Credit Default Risk Portfolio';
PRINT '================================================================';
GO
