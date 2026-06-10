# Power BI Dashboard Design — Home Credit Default Risk

## Overview

This document specifies a 3-page Power BI dashboard connected to the Gold layer star schema.

**Data Source:** SQL Server → `DataWarehouse` → Gold schema views  
**Primary View:** `gold.report_customer_risk_summary`  
**Refresh:** Manual / Daily scheduled  

---

## Page 1: Executive Overview

### Purpose
High-level portfolio health snapshot for senior stakeholders. All KPIs at a glance.

### KPI Cards (Top Row)

| KPI | DAX Measure | Format |
|-----|------------|--------|
| Total Customers | `Total Customers = DISTINCTCOUNT(report_customer_risk_summary[customer_id])` | Whole number |
| Total Loan Exposure | `Total Exposure = SUM(report_customer_risk_summary[credit_amount])` | Currency ₹ |
| Default Rate | `Default Rate = DIVIDE(CALCULATE(COUNTROWS(report_customer_risk_summary), report_customer_risk_summary[default_flag] = 1), COUNTROWS(report_customer_risk_summary))` | Percentage |
| Average Income | `Avg Income = AVERAGE(report_customer_risk_summary[income_total])` | Currency ₹ |
| Average Risk Score | `Avg Risk Score = AVERAGE(report_customer_risk_summary[composite_risk_score])` | Decimal 2 |

### Visuals

| Visual | Type | Fields | Insight |
|--------|------|--------|---------|
| Default Rate by Gender | Donut Chart | gender, default_flag | Female borrowers have lower default rates |
| Default Rate by Education | Horizontal Bar | education_type, default_rate | Higher education correlates with lower defaults |
| Risk Segment Distribution | Stacked Column | risk_segment (count) | Portfolio risk composition |
| Income Band vs Default Rate | Clustered Column | income_band, default_rate | Lower income = higher default risk |
| Exposure by Risk Segment | Treemap | risk_segment, credit_amount | Concentration risk visualization |

### Filters/Slicers
- Gender
- Age Band  
- Contract Type
- Risk Segment

---

## Page 2: Risk Analytics

### Purpose
Deep-dive risk analysis for credit officers and risk managers.

### KPI Cards (Top Row)

| KPI | DAX Measure |
|-----|------------|
| High Risk Customers | `High Risk Count = CALCULATE(COUNTROWS(report_customer_risk_summary), report_customer_risk_summary[risk_segment] IN {"High", "Critical"})` |
| Exposure at Default | `EAD = CALCULATE(SUM(report_customer_risk_summary[credit_amount]), report_customer_risk_summary[default_flag] = 1)` |
| Avg Credit-to-Income | `Avg CI Ratio = AVERAGE(report_customer_risk_summary[credit_income_ratio])` |

### Visuals

| Visual | Type | Fields | Insight |
|--------|------|--------|---------|
| Default Rate by Age Band | Column Chart | age_band, default_rate | Younger borrowers carry higher risk |
| Default Rate by Income Band | Column Chart | income_band, default_rate | Low income = high risk |
| Default Rate by Region Tier | Bar Chart | region_tier, default_rate | Geographic risk concentration |
| Top 10 Riskiest Occupations | Table | occupation_type, default_rate, count | Occupation risk ranking |
| Risk Score Distribution | Histogram (binned) | composite_risk_score | Risk shape analysis |
| Credit Utilization vs Default | Scatter | credit_utilization, default_rate | Utilization-risk correlation |

### Filters/Slicers
- Region Tier
- Income Band
- Age Band

---

## Page 3: Payment Behavior

### Purpose
Payment pattern analysis for collections and early-warning detection.

### KPI Cards (Top Row)

| KPI | DAX Measure |
|-----|------------|
| Avg Payment Delay (Days) | `Avg Delay = AVERAGE(report_customer_risk_summary[avg_payment_delay_days])` |
| Payment Completion Rate | `Completion Rate = AVERAGE(report_customer_risk_summary[payment_completion_ratio])` |
| Late Payment Rate | `Late Rate = AVERAGE(report_customer_risk_summary[late_payment_ratio])` |

### Visuals

| Visual | Type | Fields | Insight |
|--------|------|--------|---------|
| Payment Health Score Distribution | Histogram | payment_health_score | Payment health shape |
| Late Payments by Risk Segment | Stacked Bar | risk_segment, late_payment_count | High risk = more late payments |
| Payment Completion by Education | Bar | education_type, payment_completion_ratio | Education-payment correlation |
| Credit Health vs Payment Health | Scatter | credit_health_score, payment_health_score | Two-factor health assessment |
| Defaulters vs Non-Defaulters Comparison | Grouped Bar | Multiple metrics grouped by default_flag | Profile comparison |

### Filters/Slicers
- Default Flag (Yes/No)
- Risk Segment
- Gender

---

## Color Theme

```json
{
  "name": "CreditRisk",
  "dataColors": [
    "#1B3A4B", "#4A90D9", "#50C878", 
    "#FF6B6B", "#FFA726", "#7C4DFF"
  ],
  "background": "#F5F7FA",
  "foreground": "#1B3A4B"
}
```

- **Low Risk:** `#50C878` (Green)
- **Medium Risk:** `#FFA726` (Orange)  
- **High Risk:** `#FF6B6B` (Red)
- **Critical Risk:** `#8B0000` (Dark Red)

---

## Data Model Relationships

```
dim_customer (customer_key) ←→ fact_loan_application (customer_key)
dim_customer (customer_key) ←→ fact_payment_behavior (customer_key)  
dim_customer (customer_key) ←→ fact_credit_history (customer_key)
dim_income (income_key) ←→ fact_loan_application (income_key)
dim_region (region_key) ←→ fact_loan_application (region_key)
dim_time (time_key) ←→ fact_loan_application (time_key)
```

All relationships are **one-to-many** with **single-direction** cross-filtering.
