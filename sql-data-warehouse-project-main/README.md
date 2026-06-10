# 🏦 Home Credit Default Risk — Data Warehouse Project

<div align="center">

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![T-SQL](https://img.shields.io/badge/T--SQL-4479A1?style=for-the-badge&logo=databricks&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)

**End-to-end Credit Risk Data Warehouse | Medallion Architecture | Star Schema | Advanced SQL Analytics**

</div>

---

## 📌 Project Overview

A production-grade credit risk data warehouse built using **Microsoft SQL Server** and **Medallion Architecture (Bronze → Silver → Gold)**, analyzing **307,511 loan applications** and **60M+ payment records** to identify default risk patterns.

This project demonstrates:
- Enterprise ETL pipeline design with stored procedures and audit logging
- Dimensional modeling (Star Schema) with SCD Type 2 customer tracking
- Advanced SQL analytics using window functions, CTEs, and conditional aggregation
- Data quality validation across all three warehouse layers
- Power BI dashboard design for executive and risk reporting

---

## 📊 Dataset

**Source:** [Home Credit Default Risk — Kaggle](https://www.kaggle.com/c/home-credit-default-risk)

| File | Rows | Description |
|------|------|-------------|
| application_train.csv | 307,511 | Main loan application data with default label |
| application_test.csv | 48,744 | Test applications |
| bureau.csv | 1,716,428 | Credit bureau history |
| bureau_balance.csv | 27,299,925 | Monthly bureau credit balances |
| previous_application.csv | 1,670,214 | Previous loan applications |
| installments_payments.csv | 13,605,401 | Installment payment history |
| POS_CASH_balance.csv | 10,001,358 | POS and cash loan monthly balances |
| credit_card_balance.csv | 3,840,312 | Credit card monthly balances |

**Total records processed: ~58M+**

---

## 🏗️ Architecture — Medallion Design

```
┌──────────────────────────────────────────────────────────────────────┐
│                      MEDALLION ARCHITECTURE                          │
├───────────────┬─────────────────┬───────────────┬────────────────────┤
│  SOURCE (CSV) │  BRONZE (Raw)   │  SILVER (Clean)│  GOLD (Analytics) │
│               │                 │                │                    │
│  8 CSV Files  │  8 Raw Tables   │  8 Typed Tables│  5 Dimensions     │
│  ~58M rows    │  NVARCHAR(255)  │  Proper Types  │  4 Fact Tables    │
│               │  BULK INSERT    │  Business Rules│  4 Report Views   │
└───────────────┴─────────────────┴───────────────┴────────────────────┘
                                                              │
                                                    ┌─────────▼──────────┐
                                                    │    Power BI        │
                                                    │  3-Page Dashboard  │
                                                    └────────────────────┘
```

---

## ⭐ Star Schema Design

```
              dim_time ─────────────────────┐
                                            │
dim_region ──────────── fact_loan_application ──── dim_income
                                 │
                          dim_customer (SCD Type 2)
                         ┌───────┴───────┐
               fact_payment_behavior   fact_credit_history
                                           │
                                  fact_default_events
```

**5 Dimensions:** `dim_customer` (SCD2) · `dim_time` · `dim_credit` · `dim_region` · `dim_income`  
**4 Fact Tables:** `fact_loan_application` · `fact_payment_behavior` · `fact_credit_history` · `fact_default_events`

---

## 🗂️ Project Structure

```
sql-data-warehouse-project/
│
├── 📁 scripts/
│   ├── init_database.sql           ← Database + schema + audit tables
│   ├── 📁 bronze/
│   │   ├── ddl_bronze_application.sql
│   │   ├── ddl_bronze_bureau.sql
│   │   ├── ddl_bronze_payments.sql
│   │   ├── ddl_bronze_previous_application.sql
│   │   ├── ddl_bronze_reference.sql
│   │   └── proc_load_bronze.sql    ← Bulk load with audit logging
│   ├── 📁 silver/
│   │   ├── ddl_silver_*.sql        ← 5 DDL scripts
│   │   └── proc_load_silver_*.sql  ← 5 stored procedures
│   ├── 📁 gold/
│   │   ├── ddl_gold_dimensions.sql ← 5 dimension tables
│   │   ├── ddl_gold_facts.sql      ← 4 fact tables
│   │   ├── ddl_gold_reports.sql    ← 4 reporting views
│   │   ├── proc_load_gold_dimensions.sql ← SCD Type 2 merge
│   │   └── proc_load_gold_facts.sql      ← Fact loading with SK lookups
│   ├── 📁 common/
│   │   ├── sp_log_etl_start.sql
│   │   ├── sp_log_etl_end.sql
│   │   ├── sp_log_error.sql
│   │   └── sp_log_data_quality.sql
│   ├── 📁 tests/
│   │   ├── quality_checks_bronze.sql
│   │   ├── quality_checks_silver.sql
│   │   └── quality_checks_gold.sql
│   └── 📁 performance/
│       └── indexing_strategy.sql   ← 18 targeted indexes
│
├── 📁 analytics/
│   └── business_analytics.sql      ← 17 advanced SQL queries ⭐
│
├── 📁 docs/
│   ├── architecture_design.md      ← ETL flow + star schema
│   ├── data_dictionary.md          ← Column definitions + mappings
│   ├── powerbi_dashboard_design.md ← Dashboard spec + DAX measures
│   └── naming_conventions.md       ← Naming standards
│
└── 📁 datasets/                    ← CSV source files (gitignored)
```

---

## 🔷 SQL Skills Demonstrated

| Concept | Where | Example |
|---------|-------|---------|
| **Common Table Expressions (CTE)** | `business_analytics.sql` | All 17 queries use CTEs for readability |
| **ROW_NUMBER()** | Query 1 | Rank customers by composite risk score |
| **RANK()** | Queries 2, 3, 7 | Income band and region risk ranking |
| **DENSE_RANK()** | Queries 8, 14 | Occupation and education risk ranking |
| **NTILE()** | Queries 4, 9, 16 | Risk deciles, customer segmentation, histograms |
| **LAG()** | Query 5 | Previous payment amount for trend detection |
| **LEAD()** | Query 5 | Next payment amount for forward-looking analysis |
| **Running Totals** | Query 6 | `SUM() OVER (ORDER BY ... ROWS UNBOUNDED)` |
| **Moving Average** | Query 15 | `AVG() OVER (ROWS BETWEEN 2 PRECEDING AND CURRENT)` |
| **CASE Segmentation** | Queries 1, 9 | Multi-factor customer segmentation |
| **Conditional Aggregation** | Queries 11, 12 | `SUM(CASE WHEN ... THEN 1 ELSE 0 END)` |
| **Stored Procedures** | All ETL scripts | Bronze/Silver/Gold load procs |
| **SCD Type 2** | `proc_load_gold_dimensions.sql` | dim_customer with effective/end dates |
| **MERGE** | Silver procs | Upsert pattern for data loading |
| **Window % of Total** | `SUM() OVER ()` | Portfolio concentration analysis |
| **Multi-table JOINs** | Gold load procs | 5-table star schema joins |
| **TRY_CAST + NULLIF** | All silver procs | Safe type conversion pattern |
| **Error Handling** | All ETL procs | TRY/CATCH with structured error logging |

---

## 🔍 Key Business Analyses

| Analysis | SQL Concept | Business Value |
|----------|-------------|----------------|
| Top 20 High-Risk Customers | ROW_NUMBER, CTE | Credit watchlist |
| Risk Decile Distribution | NTILE(10) | Basel-style portfolio bucketing |
| Default Rate by Age Band | CTE, CASE | Demographic underwriting |
| Default Rate by Income Band | RANK, Aggregation | Affordability analysis |
| Payment Trend Detection | LAG, LEAD | Early warning system |
| Running Credit Exposure | SUM OVER | Portfolio accumulation |
| 3-Month Moving Payment Average | AVG OVER ROWS | Payment trend smoothing |
| Customer Segmentation | NTILE (3-axis) | RFM-style grouping |
| Credit Utilization Bands | CASE, GROUP BY | Revolving credit risk |
| Portfolio KPI Summary | Conditional AGG | Executive reporting |

---

## 🎛️ Power BI Dashboard (3 Pages)

| Page | Focus | Key Visuals |
|------|-------|-------------|
| **Executive Overview** | Portfolio health | Default rate card, income vs default bar, risk segment donut |
| **Risk Analytics** | Risk deep-dive | Age-band defaults, income-band risk, high-risk customer table |
| **Payment Behavior** | Collections insight | Payment health distribution, late payment trends |

Full design spec: [`docs/powerbi_dashboard_design.md`](docs/powerbi_dashboard_design.md)

---

## ⚙️ How to Run This Project

**Prerequisites:** SQL Server 2019+, SSMS, CSV files in `C:\home-credit-default-risk\`

```sql
-- Step 1: Initialize database, schemas, and audit tables
EXEC ('USE master; ...');  -- Run scripts/init_database.sql

-- Step 2: Create Bronze layer tables
-- Run all: scripts/bronze/ddl_bronze_*.sql

-- Step 3: Load Bronze layer
EXEC bronze.load_bronze;

-- Step 4: Create Silver layer tables
-- Run all: scripts/silver/ddl_silver_*.sql

-- Step 5: Load Silver layer
EXEC silver.load_application_train;
EXEC silver.load_application_test;
EXEC silver.load_bureau;
EXEC silver.load_payments;
EXEC silver.load_previous_application;

-- Step 6: Create Gold layer (dimensions + facts)
-- Run: scripts/gold/ddl_gold_dimensions.sql
-- Run: scripts/gold/ddl_gold_facts.sql
-- Run: scripts/gold/ddl_gold_reports.sql

-- Step 7: Load Gold layer
EXEC gold.load_dimensions;
EXEC gold.load_facts;

-- Step 8: Apply indexes
-- Run: scripts/performance/indexing_strategy.sql

-- Step 9: Validate all layers
-- Run: scripts/tests/quality_checks_bronze.sql
-- Run: scripts/tests/quality_checks_silver.sql
-- Run: scripts/tests/quality_checks_gold.sql

-- Step 10: Run analytics
-- Open: analytics/business_analytics.sql
```

---

## ✅ Data Quality Framework

| Layer | Checks | Examples |
|-------|--------|---------|
| **Bronze** | Null checks, row counts, duplicates | NULL customer_id, zero-row detection |
| **Silver** | Type validation, business rules, outliers | Negative income, future employment dates |
| **Gold** | Referential integrity, financial sanity, SCD2 validation | Orphaned fact rows, risk score bounds |

---

## 📈 Project Metrics

| Metric | Value |
|--------|-------|
| Total Records Processed | ~58 million |
| Loan Applications Analyzed | 307,511 |
| SQL Scripts Written | 25+ |
| Tables Created | 21 (8 Bronze + 8 Silver + 5 Dim) |
| Fact Tables | 4 |
| Report Views | 4 |
| Analytics Queries | 17 |
| Data Quality Checks | 30+ |
| Indexes Created | 18 |

---

## 📄 Resume Bullets

### Data Analyst
> Built a credit risk analytics data warehouse processing **58M+ records** across **8 source tables** using SQL Server Medallion Architecture, implementing **17 advanced SQL analyses** with window functions (ROW_NUMBER, RANK, LAG, LEAD, NTILE) to identify default risk patterns across **307K loan applications**.

### SQL Developer
> Designed and developed **25+ T-SQL stored procedures** with TRY/CATCH error handling, audit logging, and per-table row count tracking; implemented **star schema** with SCD Type 2 dimensional tracking and **18 performance indexes** for analytical workloads.

### Analytics Engineer
> Built end-to-end ETL pipeline using Medallion Architecture (Bronze→Silver→Gold), implementing data type casting, NULL handling, categorical standardization, and derived financial ratios (credit-to-income, annuity-to-income) across **8 data domains**.

### BlackRock / Finance
> Engineered credit risk data warehouse analyzing **$X billion in loan exposure** across **307K borrowers**, implementing composite risk scoring from external bureau sources, risk decile analysis (Basel-style), and default event tracking with Exposure at Default (EAD) calculation.

---

## 🛠️ Tech Stack

| Tool | Usage |
|------|-------|
| SQL Server 2019 | Database engine |
| T-SQL | ETL, analytics, stored procedures |
| SSMS | Development environment |
| Power BI Desktop | Dashboard and visualization |
| Git / GitHub | Version control |

---

## 👤 Author

**Anumodit Shukla**  
📧 Connect on [LinkedIn](https://linkedin.com) | 🌐 [GitHub](https://github.com)

---

<div align="center">

⭐ **If this project was useful, please give it a star!**

</div>
