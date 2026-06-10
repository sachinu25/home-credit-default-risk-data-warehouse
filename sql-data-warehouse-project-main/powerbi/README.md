# Power BI Dashboard — Home Credit Default Risk

This folder contains the Power BI dashboard for the Home Credit Default Risk Data Warehouse project.

## Dashboard File

> **`HomeCredit_Risk_Dashboard.pbix`** — Connect to your local SQL Server instance.

## Connection Setup

1. Open `HomeCredit_Risk_Dashboard.pbix` in Power BI Desktop
2. Go to **Home → Transform Data → Data Source Settings**
3. Update the server name to your SQL Server instance
4. Ensure the `DataWarehouse` database is accessible
5. Click **Refresh** to load all data

## Data Sources (Gold Layer Views)

| Page | Primary Source |
|------|---------------|
| Executive Overview | `gold.report_customer_risk_summary` |
| Risk Analytics | `gold.report_customer_risk_summary` + `gold.report_portfolio_overview` |
| Payment Behavior | `gold.report_customer_risk_summary` |

## Dashboard Pages

| Page | Description |
|------|-------------|
| **Page 1 — Executive Overview** | Portfolio KPIs, default rate, risk segments |
| **Page 2 — Risk Analytics** | Age/income/region risk breakdown, high-risk customers |
| **Page 3 — Payment Behavior** | Payment health, late payment trends, delinquency |

## Design Specification

Full DAX measures, visual types, KPI definitions, and color theme:  
→ [`../docs/powerbi_dashboard_design.md`](../docs/powerbi_dashboard_design.md)
