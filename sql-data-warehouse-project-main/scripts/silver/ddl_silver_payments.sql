USE DataWarehouse;
GO

/*
===============================================================================
DDL Script: Create Silver Payment and Balance Tables
===============================================================================
Tables:
    - silver.installments_payments
    - silver.POS_CASH_balance
    - silver.credit_card_balance
===============================================================================
*/

DROP TABLE IF EXISTS silver.credit_card_balance;
DROP TABLE IF EXISTS silver.POS_CASH_balance;
DROP TABLE IF EXISTS silver.installments_payments;
GO

CREATE TABLE silver.installments_payments (
    sk_id_prev INT,
    sk_id_curr INT,

    installment_version DECIMAL(10,2),
    installment_number INT,

    days_instalment INT,
    days_entry_payment DECIMAL(18,2),

    instalment_amount DECIMAL(18,2),
    payment_amount DECIMAL(18,2),

    payment_difference DECIMAL(18,2),
    payment_delay_days DECIMAL(18,2),

    underpaid_flag TINYINT,
    late_payment_flag TINYINT,

    dwh_load_date DATETIME2 DEFAULT GETDATE()
);
GO

CREATE TABLE silver.POS_CASH_balance (
    sk_id_prev INT,
    sk_id_curr INT,

    months_balance INT,

    installment_count DECIMAL(10,2),
    future_installment_count DECIMAL(10,2),

    contract_status NVARCHAR(50),

    days_past_due INT,
    days_past_due_def INT,

    dpd_flag TINYINT,

    dwh_load_date DATETIME2 DEFAULT GETDATE()
);
GO

CREATE TABLE silver.credit_card_balance (
    sk_id_prev INT,
    sk_id_curr INT,

    months_balance INT,

    balance_amount DECIMAL(18,2),
    credit_limit_actual DECIMAL(18,2),

    drawings_atm_current DECIMAL(18,2),
    drawings_current DECIMAL(18,2),
    drawings_other_current DECIMAL(18,2),
    drawings_pos_current DECIMAL(18,2),

    min_regular_payment DECIMAL(18,2),
    payment_current DECIMAL(18,2),
    payment_total_current DECIMAL(18,2),

    receivable_principal DECIMAL(18,2),
    receivable_amount DECIMAL(18,2),
    total_receivable DECIMAL(18,2),

    drawings_atm_count DECIMAL(10,2),
    drawings_count INT,
    drawings_other_count DECIMAL(10,2),
    drawings_pos_count DECIMAL(10,2),

    matured_installment_count DECIMAL(10,2),

    contract_status NVARCHAR(50),

    days_past_due INT,
    days_past_due_def INT,

    credit_utilization_ratio DECIMAL(18,4),
    dpd_flag TINYINT,

    dwh_load_date DATETIME2 DEFAULT GETDATE()
);
GO