# Data Dictionary — Home Credit Default Risk Data Warehouse

## Overview
This document maps every table and column across the Bronze → Silver → Gold layers, including business meaning, data types, and transformation logic.

---

## Bronze Layer (Raw Landing)

All columns are `NVARCHAR(255)` — exact copy from CSV source. No transformations.

### bronze.application_train

| Column | Source CSV | Description |
|--------|-----------|-------------|
| SK_ID_CURR | application_train.csv | Unique customer/application ID |
| TARGET | application_train.csv | Default flag: 1 = defaulted, 0 = repaid |
| NAME_CONTRACT_TYPE | application_train.csv | Cash loan or revolving loan |
| CODE_GENDER | application_train.csv | Gender: M, F, XNA |
| FLAG_OWN_CAR | application_train.csv | Owns a car: Y/N |
| FLAG_OWN_REALTY | application_train.csv | Owns property: Y/N |
| CNT_CHILDREN | application_train.csv | Number of children |
| AMT_INCOME_TOTAL | application_train.csv | Total annual income |
| AMT_CREDIT | application_train.csv | Credit amount of the loan |
| AMT_ANNUITY | application_train.csv | Loan annuity payment |
| AMT_GOODS_PRICE | application_train.csv | Price of the goods for which the loan is given |
| NAME_INCOME_TYPE | application_train.csv | Income source type |
| NAME_EDUCATION_TYPE | application_train.csv | Highest education level |
| NAME_FAMILY_STATUS | application_train.csv | Marital / family status |
| NAME_HOUSING_TYPE | application_train.csv | Housing situation |
| DAYS_BIRTH | application_train.csv | Age in days (negative from application date) |
| DAYS_EMPLOYED | application_train.csv | Employment duration in days |
| OCCUPATION_TYPE | application_train.csv | Occupation category |
| EXT_SOURCE_1 | application_train.csv | External risk score 1 (normalized 0–1) |
| EXT_SOURCE_2 | application_train.csv | External risk score 2 (normalized 0–1) |
| EXT_SOURCE_3 | application_train.csv | External risk score 3 (normalized 0–1) |
| dwh_load_date | System | ETL load timestamp |

### bronze.bureau

| Column | Source CSV | Description |
|--------|-----------|-------------|
| SK_ID_CURR | bureau.csv | Customer ID (FK to application) |
| SK_ID_BUREAU | bureau.csv | Bureau record ID |
| CREDIT_ACTIVE | bureau.csv | Status: Active, Closed, Sold, Bad debt |
| CREDIT_CURRENCY | bureau.csv | Currency of the credit |
| DAYS_CREDIT | bureau.csv | Days since bureau credit was opened |
| CREDIT_DAY_OVERDUE | bureau.csv | Days past due at time of report |
| AMT_CREDIT_SUM | bureau.csv | Total credit amount |
| AMT_CREDIT_SUM_DEBT | bureau.csv | Current outstanding debt |
| AMT_CREDIT_SUM_OVERDUE | bureau.csv | Amount currently overdue |
| CREDIT_TYPE | bureau.csv | Type of credit (Consumer, Credit card, Mortgage, etc.) |
| dwh_load_date | System | ETL load timestamp |

### bronze.installments_payments

| Column | Source CSV | Description |
|--------|-----------|-------------|
| SK_ID_PREV | installments_payments.csv | Previous application ID |
| SK_ID_CURR | installments_payments.csv | Customer ID |
| NUM_INSTALMENT_NUMBER | installments_payments.csv | Installment sequence number |
| DAYS_INSTALMENT | installments_payments.csv | Scheduled payment day |
| DAYS_ENTRY_PAYMENT | installments_payments.csv | Actual payment day |
| AMT_INSTALMENT | installments_payments.csv | Scheduled payment amount |
| AMT_PAYMENT | installments_payments.csv | Actual payment amount |
| dwh_load_date | System | ETL load timestamp |

---

## Silver Layer (Cleaned & Typed)

### silver.application_train

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| sk_id_curr | INT | SK_ID_CURR | TRY_CAST from NVARCHAR |
| target | TINYINT | TARGET | TRY_CAST |
| contract_type | NVARCHAR(50) | NAME_CONTRACT_TYPE | TRIM, NULLIF |
| gender | NVARCHAR(20) | CODE_GENDER | CASE: M→Male, F→Female, XNA→NULL |
| owns_car | NVARCHAR(10) | FLAG_OWN_CAR | CASE: Y→Yes, N→No |
| owns_realty | NVARCHAR(10) | FLAG_OWN_REALTY | CASE: Y→Yes, N→No |
| income_total | DECIMAL(18,2) | AMT_INCOME_TOTAL | TRY_CAST |
| credit_amount | DECIMAL(18,2) | AMT_CREDIT | TRY_CAST |
| annuity_amount | DECIMAL(18,2) | AMT_ANNUITY | TRY_CAST |
| age_years | DECIMAL(5,2) | DAYS_BIRTH | `ABS(DAYS_BIRTH) / 365.25` |
| employment_years | DECIMAL(8,2) | DAYS_EMPLOYED | `ABS(DAYS_EMPLOYED) / 365.25` (filtered for 365243) |
| credit_income_ratio | DECIMAL(18,4) | Derived | `credit_amount / income_total` |
| annuity_income_ratio | DECIMAL(18,4) | Derived | `annuity_amount / income_total` |
| goods_credit_ratio | DECIMAL(18,4) | Derived | `goods_price / credit_amount` |
| dwh_load_date | DATETIME2 | System | GETDATE() at load time |

### silver.bureau

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| sk_id_curr | INT | SK_ID_CURR | TRY_CAST |
| sk_id_bureau | INT | SK_ID_BUREAU | TRY_CAST |
| credit_active | NVARCHAR(50) | CREDIT_ACTIVE | TRIM, NULLIF |
| credit_sum | DECIMAL(18,2) | AMT_CREDIT_SUM | TRY_CAST |
| credit_sum_debt | DECIMAL(18,2) | AMT_CREDIT_SUM_DEBT | TRY_CAST |
| credit_debt_ratio | DECIMAL(18,4) | Derived | `credit_sum_debt / credit_sum` (when > 0) |
| overdue_flag | INT | Derived | `CASE WHEN credit_day_overdue > 0 THEN 1 ELSE 0` |
| credit_type | NVARCHAR(100) | CREDIT_TYPE | TRIM |

### silver.installments_payments

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| sk_id_curr | INT | SK_ID_CURR | TRY_CAST |
| installment_number | INT | NUM_INSTALMENT_NUMBER | TRY_CAST |
| instalment_amount | DECIMAL(18,2) | AMT_INSTALMENT | TRY_CAST |
| payment_amount | DECIMAL(18,2) | AMT_PAYMENT | TRY_CAST |
| payment_difference | DECIMAL(18,2) | Derived | `instalment_amount - payment_amount` |
| payment_delay_days | DECIMAL(18,2) | Derived | `days_entry_payment - days_instalment` |
| underpaid_flag | INT | Derived | `CASE WHEN payment < instalment THEN 1` |
| late_payment_flag | INT | Derived | `CASE WHEN entry > instalment THEN 1` |

---

## Gold Layer (Star Schema)

### gold.dim_customer (SCD Type 2)

| Column | Type | Business Meaning |
|--------|------|-----------------|
| customer_key | INT (IDENTITY) | Surrogate key — stable, system-generated |
| customer_id | INT | Business key — links to SK_ID_CURR |
| gender | NVARCHAR(20) | Customer gender |
| age_years | DECIMAL(5,2) | Customer age in years |
| age_band | NVARCHAR(20) | Derived: 18-24, 25-34, 35-44, 45-54, 55-64, 65+ |
| composite_risk_score | DECIMAL(10,4) | Weighted avg of EXT_SOURCE 1/2/3 |
| effective_date | DATE | SCD2: When this version became active |
| end_date | DATE | SCD2: When superseded (NULL = current) |
| is_current | BIT | SCD2: 1 = active version |

### gold.dim_time

| Column | Type | Business Meaning |
|--------|------|-----------------|
| time_key | INT | Date key in YYYYMMDD format |
| full_date | DATE | Calendar date |
| day_name | NVARCHAR(10) | Monday, Tuesday, etc. |
| month_name | NVARCHAR(10) | January, February, etc. |
| quarter_name | NVARCHAR(2) | Q1, Q2, Q3, Q4 |
| calendar_year | SMALLINT | Calendar year |
| fiscal_year | SMALLINT | Fiscal year (July start) |
| is_weekend | BIT | Weekend flag |

### gold.fact_loan_application

| Column | Type | Business Meaning |
|--------|------|-----------------|
| loan_application_key | INT (IDENTITY) | Surrogate key |
| customer_key | INT (FK) | Links to dim_customer |
| time_key | INT (FK) | Links to dim_time |
| region_key | INT (FK) | Links to dim_region |
| income_key | INT (FK) | Links to dim_income |
| default_flag | TINYINT | 0 = Repaid, 1 = Defaulted |
| credit_amount | DECIMAL(18,2) | Loan amount |
| income_total | DECIMAL(18,2) | Customer income |
| credit_income_ratio | DECIMAL(18,4) | Credit / Income ratio |
| risk_segment | NVARCHAR(20) | Low, Medium, High, Critical |
| composite_risk_score | DECIMAL(10,4) | Weighted external risk score |

### gold.fact_payment_behavior

| Column | Type | Business Meaning |
|--------|------|-----------------|
| customer_key | INT (FK) | Links to dim_customer |
| total_installments | INT | Count of payment records |
| late_payment_count | INT | Count of late payments |
| payment_completion_ratio | DECIMAL(10,4) | Total paid / Total owed |
| payment_health_score | DECIMAL(5,2) | 0-100 score (higher = better payer) |

### gold.fact_credit_history

| Column | Type | Business Meaning |
|--------|------|-----------------|
| customer_key | INT (FK) | Links to dim_customer |
| total_bureau_records | INT | Total credit bureau entries |
| active_credit_count | INT | Currently active credit lines |
| overdue_credit_count | INT | Credits with overdue payments |
| credit_utilization | DECIMAL(10,4) | Total debt / Total credit |
| credit_health_score | DECIMAL(5,2) | 0-100 score (higher = better history) |

### gold.fact_default_events

| Column | Type | Business Meaning |
|--------|------|-----------------|
| customer_key | INT (FK) | Links to dim_customer |
| credit_amount | DECIMAL(18,2) | Exposure at default |
| risk_segment | NVARCHAR(20) | Risk segment at time of default |
| composite_risk_score | DECIMAL(10,4) | Risk score at default |
