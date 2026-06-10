USE DataWarehouse;
GO

DROP TABLE IF EXISTS silver.application_test;
GO

CREATE TABLE silver.application_test (

    sk_id_curr INT,

    contract_type NVARCHAR(50),
    gender NVARCHAR(20),

    owns_car NVARCHAR(10),
    owns_realty NVARCHAR(10),

    children_count INT,

    income_total DECIMAL(18,2),
    credit_amount DECIMAL(18,2),
    annuity_amount DECIMAL(18,2),
    goods_price DECIMAL(18,2),

    type_suite NVARCHAR(100),
    income_type NVARCHAR(100),
    education_type NVARCHAR(100),
    family_status NVARCHAR(100),
    housing_type NVARCHAR(100),

    region_population_relative DECIMAL(18,10),

    days_birth INT,
    age_years DECIMAL(5,2),

    days_employed INT,
    employment_years DECIMAL(8,2),

    days_registration DECIMAL(18,2),
    days_id_publish INT,

    own_car_age DECIMAL(10,2),

    flag_mobile TINYINT,
    flag_emp_phone TINYINT,
    flag_work_phone TINYINT,
    flag_cont_mobile TINYINT,
    flag_phone TINYINT,
    flag_email TINYINT,

    occupation_type NVARCHAR(100),

    family_members_count DECIMAL(10,2),

    region_rating_client TINYINT,
    region_rating_client_w_city TINYINT,

    weekday_application_start NVARCHAR(20),
    hour_application_start TINYINT,

    organization_type NVARCHAR(100),

    ext_source_1 DECIMAL(18,10),
    ext_source_2 DECIMAL(18,10),
    ext_source_3 DECIMAL(18,10),

    social_circle_obs_30 DECIMAL(10,2),
    social_circle_def_30 DECIMAL(10,2),
    social_circle_obs_60 DECIMAL(10,2),
    social_circle_def_60 DECIMAL(10,2),

    days_last_phone_change DECIMAL(10,2),

    req_credit_bureau_hour DECIMAL(10,2),
    req_credit_bureau_day DECIMAL(10,2),
    req_credit_bureau_week DECIMAL(10,2),
    req_credit_bureau_month DECIMAL(10,2),
    req_credit_bureau_quarter DECIMAL(10,2),
    req_credit_bureau_year DECIMAL(10,2),

    credit_income_ratio DECIMAL(18,4),
    annuity_income_ratio DECIMAL(18,4),
    goods_credit_ratio DECIMAL(18,4),

    dwh_load_date DATETIME2 DEFAULT GETDATE()

);
GO