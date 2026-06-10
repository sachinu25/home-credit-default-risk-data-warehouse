# Naming Conventions — Home Credit Default Risk Data Warehouse

## 1. Schema Names

| Schema | Layer | Purpose |
|--------|-------|---------|
| `bronze` | Bronze | Raw landing zone — source-identical |
| `silver` | Silver | Cleaned, typed, standardized |
| `gold` | Gold | Business-ready star schema |
| `audit` | Cross-layer | ETL logging, error tracking, metadata |

---

## 2. Table Naming

| Pattern | Example | Rule |
|---------|---------|------|
| Bronze tables | `bronze.application_train` | Match source CSV filename (lowercase, underscores) |
| Silver tables | `silver.application_train` | Match bronze table name — same name, different schema |
| Dimension tables | `gold.dim_customer` | Prefix: `dim_` |
| Fact tables | `gold.fact_loan_application` | Prefix: `fact_` |
| Report views | `gold.report_customer_risk_summary` | Prefix: `report_` |
| Audit tables | `audit.etl_run_log` | Descriptive noun phrase |

---

## 3. Column Naming

| Pattern | Example | Rule |
|---------|---------|------|
| Business key | `customer_id` | Source field name, lowercase, snake_case |
| Surrogate key | `customer_key` | `<entity>_key` — IDENTITY surrogate |
| Foreign key | `customer_key` | Same as referenced PK name |
| Amount fields | `credit_amount`, `income_total` | Noun describing the amount |
| Count fields | `children_count`, `late_payment_count` | `<noun>_count` |
| Flag fields | `default_flag`, `late_payment_flag`, `is_current` | `<noun>_flag` or `is_<state>` |
| Ratio fields | `credit_income_ratio`, `payment_completion_ratio` | `<numerator>_<denominator>_ratio` |
| Date fields | `effective_date`, `end_date` | `<purpose>_date` |
| Timestamp fields | `dwh_load_date`, `dwh_created_date` | `dwh_<purpose>_date` |
| Score fields | `composite_risk_score`, `payment_health_score` | `<noun>_score` |
| Band/Tier fields | `age_band`, `income_band`, `region_tier` | `<noun>_band` or `<noun>_tier` |

---

## 4. Stored Procedure Naming

| Pattern | Example | Rule |
|---------|---------|------|
| Load procedures | `bronze.load_bronze` | `<schema>.load_<target>` |
| Silver loaders | `silver.load_application_train` | `silver.load_<table_name>` |
| Gold loaders | `gold.load_dimensions`, `gold.load_facts` | `gold.load_<group>` |
| Audit utilities | `audit.sp_log_etl_start` | `audit.sp_log_<action>` |

---

## 5. File Naming

| Pattern | Example | Rule |
|---------|---------|------|
| DDL scripts | `ddl_bronze_application.sql` | `ddl_<layer>_<entity>.sql` |
| Load procedures | `proc_load_bronze.sql` | `proc_load_<layer>[_entity].sql` |
| Test/quality files | `quality_checks_bronze.sql` | `quality_checks_<layer>.sql` |
| Analytics files | `business_analytics.sql` | Descriptive noun phrase |
| Documentation | `data_dictionary.md` | Descriptive, snake_case |

---

## 6. Silver Transformation Standards

| Rule | Example |
|------|---------|
| Safe casting | `TRY_CAST(NULLIF(column, '') AS INT)` |
| String cleaning | `TRIM(NULLIF(column, ''))` |
| Boolean standardization | `CASE WHEN col = 'Y' THEN 'Yes' WHEN col = 'N' THEN 'No' END` |
| Ratio derivation | Guard against division by zero: `CASE WHEN denominator > 0 THEN ... END` |
| Derived date fields | `ABS(DAYS_BIRTH) / 365.25` for `age_years` |

---

## 7. SCD Type 2 Column Standards

For all Type 2 dimensions:

| Column | Type | Default |
|--------|------|---------|
| `effective_date` | `DATE` | `CAST(GETDATE() AS DATE)` |
| `end_date` | `DATE` | `NULL` (active rows) |
| `is_current` | `BIT` | `1` (active), `0` (historical) |
