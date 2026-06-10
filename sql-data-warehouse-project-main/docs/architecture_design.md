# Architecture Design — Home Credit Default Risk Data Warehouse

## 1. System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        DATA WAREHOUSE ARCHITECTURE                      │
│                     Medallion Architecture (3-Layer)                     │
├─────────────┬──────────────────┬──────────────────┬────────────────────┤
│             │                  │                  │                    │
│  SOURCE     │   BRONZE LAYER   │   SILVER LAYER   │    GOLD LAYER      │
│  (CSV)      │   (Raw Landing)  │   (Cleaned)      │    (Star Schema)   │
│             │                  │                  │                    │
│  8 CSV      │   8 Raw Tables   │   8 Typed Tables │  5 Dimensions      │
│  Files      │   NVARCHAR(255)  │   Proper Types   │  4 Fact Tables     │
│  60M+ rows  │   BULK INSERT    │   TRY_CAST       │  4 Report Views    │
│             │                  │   Business Rules │  FK Constraints    │
│             │                  │                  │                    │
└─────────────┴──────────────────┴──────────────────┴────────────────────┘
         │              │                 │                    │
         ▼              ▼                 ▼                    ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │                      AUDIT & METADATA LAYER                      │
    │  etl_run_log │ etl_error_log │ data_quality_log │ etl_metadata   │
    │                      data_lineage                                │
    └──────────────────────────────────────────────────────────────────┘
```

---

## 2. Medallion Architecture Detail

### Bronze Layer — Raw Landing Zone

**Purpose:** Ingest raw CSV data exactly as-is, preserving source fidelity.

| Property | Value |
|----------|-------|
| Schema | `bronze` |
| Data Types | All `NVARCHAR(255)` |
| Load Method | `BULK INSERT` from CSV |
| Load Pattern | Truncate and Reload |
| Tables | 8 (application_train, application_test, bureau, bureau_balance, previous_application, installments_payments, POS_CASH_balance, credit_card_balance) |
| Added Column | `dwh_load_date DATETIME2` |
| Error Handling | Per-table TRY/CATCH with audit logging |

### Silver Layer — Cleaned & Standardized

**Purpose:** Apply data type casting, NULL handling, categorical standardization, and derived business columns.

| Property | Value |
|----------|-------|
| Schema | `silver` |
| Data Types | Proper types (INT, DECIMAL, NVARCHAR) |
| Load Method | `INSERT INTO ... SELECT` from Bronze |
| Transformations | TRY_CAST, NULLIF, TRIM, CASE standardization |
| Derived Columns | credit_income_ratio, age_years, employment_years, payment_delay_days, underpaid_flag, late_payment_flag, credit_debt_ratio, overdue_flag, dpd_flag, credit_utilization_ratio |
| Tables | 8 (matching Bronze) |

### Gold Layer — Business-Ready Star Schema

**Purpose:** Dimensional model for analytics and Power BI consumption.

| Property | Value |
|----------|-------|
| Schema | `gold` |
| Model | Kimball Star Schema |
| Dimensions | 5 (customer, time, credit, region, income) |
| Facts | 4 (loan_application, payment_behavior, credit_history, default_events) |
| SCD Type | Type 2 on dim_customer |
| Key Type | Surrogate keys (IDENTITY) |
| Constraints | Foreign keys on all fact-dimension relationships |

---

## 3. ETL Pipeline Flow

```
Step 1: EXEC bronze.load_bronze
        ├── BULK INSERT from CSV → staging temp table
        ├── INSERT INTO bronze tables + dwh_load_date
        ├── Per-table TRY/CATCH
        └── Audit logging (sp_log_etl_start/end)

Step 2: EXEC silver.load_application_train
        EXEC silver.load_application_test
        EXEC silver.load_bureau
        EXEC silver.load_payments
        EXEC silver.load_previous_application
        ├── TRUNCATE target tables
        ├── INSERT INTO ... SELECT with transformations
        ├── TRY_CAST, NULLIF, CASE standardization
        └── Derived business columns

Step 3: EXEC gold.load_dimensions
        ├── dim_time      — Calendar generation (CTE recursive)
        ├── dim_credit     — Distinct credit types from silver.bureau
        ├── dim_region     — Distinct regions from silver.application_train
        ├── dim_income     — Static income band lookup
        └── dim_customer   — SCD Type 2 MERGE from silver.application_train

Step 4: EXEC gold.load_facts
        ├── fact_loan_application  — JOIN silver + dimension key lookups
        ├── fact_payment_behavior  — GROUP BY customer + payment aggregates
        ├── fact_credit_history    — GROUP BY customer + bureau aggregates
        └── fact_default_events    — Filtered: default_flag = 1 only
```

---

## 4. Star Schema Entity Relationship

```
                    ┌─────────────────┐
                    │   dim_time      │
                    │   (time_key PK) │
                    └───────┬─────────┘
                            │
┌─────────────────┐         │         ┌─────────────────┐
│   dim_region    │         │         │   dim_income     │
│  (region_key PK)├────┐    │    ┌────┤  (income_key PK) │
└─────────────────┘    │    │    │    └─────────────────┘
                       │    │    │
                  ┌────▼────▼────▼──────────────┐
                  │                              │
                  │   fact_loan_application      │
                  │   (loan_application_key PK)  │
                  │                              │
                  │   customer_key (FK)          │
                  │   time_key (FK)              │
                  │   region_key (FK)            │
                  │   income_key (FK)            │
                  │                              │
                  └──────────┬───────────────────┘
                             │
                    ┌────────▼────────┐
                    │  dim_customer   │
                    │ (customer_key PK)│
                    │  SCD Type 2     │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
    ┌─────────▼──┐  ┌───────▼────┐  ┌──────▼──────────┐
    │ fact_      │  │ fact_      │  │ fact_            │
    │ payment_   │  │ credit_    │  │ default_         │
    │ behavior   │  │ history    │  │ events           │
    └────────────┘  └────────────┘  └─────────────────┘
```

---

## 5. Data Lineage Summary

| Source | Target | Transformation |
|--------|--------|----------------|
| CSV files | Bronze tables | BULK INSERT (raw copy) |
| Bronze tables | Silver tables | Type casting, NULL handling, business rules |
| Silver application_train | Gold dim_customer | SCD Type 2 merge, age band derivation, composite risk score |
| Silver application_train | Gold fact_loan_application | Dimension key lookups, risk segmentation |
| Silver installments_payments | Gold fact_payment_behavior | Customer-level aggregation, health score |
| Silver bureau | Gold fact_credit_history | Customer-level aggregation, health score |
| Silver application_train | Gold fact_default_events | Filtered defaults + enriched context |
| Calendar generation | Gold dim_time | CTE-based date sequence (2010–2030) |
| Silver bureau | Gold dim_credit | Distinct credit types with risk weights |
| Silver application_train | Gold dim_region | Distinct region rating combinations |
| Static lookup | Gold dim_income | Pre-defined income bands |

---

## 6. Audit Framework

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| audit.etl_run_log | Track every procedure execution | run_id, procedure_name, status, rows_affected, duration |
| audit.etl_error_log | Capture detailed error info | error_number, error_message, error_line |
| audit.data_quality_log | Log DQ check results | check_name, result_status, records_affected |
| audit.etl_metadata | Track load watermarks | table_name, last_load_date, row_count |
| audit.data_lineage | Document source-to-target mapping | source_table, target_table, transformation_type |

---

## 7. Technology Stack

| Component | Technology |
|-----------|-----------|
| Database | Microsoft SQL Server |
| Language | T-SQL |
| Architecture | Medallion (Bronze-Silver-Gold) |
| Data Model | Kimball Star Schema |
| SCD Pattern | Type 2 (effective_date/end_date) |
| ETL Pattern | Stored Procedures |
| Visualization | Power BI |
| Version Control | Git / GitHub |
