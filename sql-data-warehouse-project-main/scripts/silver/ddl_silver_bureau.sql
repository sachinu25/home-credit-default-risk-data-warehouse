USE DataWarehouse;
GO

/*
===============================================================================
DDL Script: Create Silver Bureau Tables
===============================================================================
*/

DROP TABLE IF EXISTS silver.bureau_balance;
DROP TABLE IF EXISTS silver.bureau;
GO

CREATE TABLE silver.bureau (

    sk_id_curr INT,
    sk_id_bureau INT,

    credit_active NVARCHAR(50),
    credit_currency NVARCHAR(50),

    days_credit INT,
    credit_day_overdue INT,

    days_credit_enddate DECIMAL(18,2),
    days_enddate_fact DECIMAL(18,2),

    credit_max_overdue DECIMAL(18,2),

    credit_prolong_count INT,

    credit_sum DECIMAL(18,2),
    credit_sum_debt DECIMAL(18,2),
    credit_sum_limit DECIMAL(18,2),
    credit_sum_overdue DECIMAL(18,2),

    credit_type NVARCHAR(100),

    days_credit_update INT,

    annuity_amount DECIMAL(18,2),

    credit_debt_ratio DECIMAL(18,4),
    overdue_flag TINYINT,

    dwh_load_date DATETIME2 DEFAULT GETDATE()
);
GO

CREATE TABLE silver.bureau_balance (

    sk_id_bureau INT,

    months_balance INT,

    status NVARCHAR(20),

    status_group NVARCHAR(50),

    dwh_load_date DATETIME2 DEFAULT GETDATE()
);
GO