USE DataWarehouse;
GO

/*
===============================================================================
DDL Script: Create Silver Previous Application Table
===============================================================================
*/

DROP TABLE IF EXISTS silver.previous_application;
GO

CREATE TABLE silver.previous_application (

    sk_id_prev INT,
    sk_id_curr INT,

    contract_type NVARCHAR(50),

    annuity_amount DECIMAL(18,2),
    application_amount DECIMAL(18,2),
    credit_amount DECIMAL(18,2),
    down_payment_amount DECIMAL(18,2),
    goods_price DECIMAL(18,2),

    weekday_application_start NVARCHAR(20),
    hour_application_start TINYINT,

    last_application_per_contract NVARCHAR(10),
    last_application_in_day TINYINT,

    down_payment_rate DECIMAL(18,10),

    cash_loan_purpose NVARCHAR(100),
    contract_status NVARCHAR(50),

    days_decision INT,

    payment_type NVARCHAR(100),
    reject_reason NVARCHAR(50),

    client_type NVARCHAR(50),
    goods_category NVARCHAR(100),
    portfolio_type NVARCHAR(50),
    product_type NVARCHAR(50),
    channel_type NVARCHAR(100),

    sellerplace_area INT,
    seller_industry NVARCHAR(100),

    payment_count DECIMAL(10,2),
    yield_group NVARCHAR(50),
    product_combination NVARCHAR(100),

    credit_application_ratio DECIMAL(18,4),
    down_payment_credit_ratio DECIMAL(18,4),

    approval_flag TINYINT,
    rejection_flag TINYINT,

    dwh_load_date DATETIME2 DEFAULT GETDATE()
);
GO