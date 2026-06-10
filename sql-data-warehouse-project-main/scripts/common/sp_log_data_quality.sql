USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: sp_log_data_quality
===============================================================================
Purpose:
    Logs data quality check results to audit.data_quality_log.
    Used by all test scripts to create a centralized quality audit trail.

Parameters:
    @batch_id         - Batch identifier for grouping checks
    @check_name       - Descriptive name of the check
    @layer            - Data warehouse layer (bronze, silver, gold)
    @table_name       - Table being validated
    @check_type       - Category: NULL_CHECK, DUPLICATE, REFERENTIAL, 
                        BUSINESS_RULE, FRESHNESS, SCHEMA_DRIFT, FINANCIAL_SANITY
    @result_status    - PASS, FAIL, or WARN
    @records_affected - Number of records that failed the check
    @threshold        - Acceptable threshold (0 = zero tolerance)
    @details          - Additional details or context

Usage:
    EXEC audit.sp_log_data_quality
        @check_name = 'null_customer_id',
        @layer = 'gold',
        @table_name = 'dim_customer',
        @check_type = 'NULL_CHECK',
        @result_status = 'PASS',
        @records_affected = 0;
===============================================================================
*/

CREATE OR ALTER PROCEDURE audit.sp_log_data_quality
    @batch_id           UNIQUEIDENTIFIER = NULL,
    @check_name         NVARCHAR(255),
    @layer              NVARCHAR(20),
    @table_name         NVARCHAR(255),
    @check_type         NVARCHAR(50),
    @result_status      NVARCHAR(10),
    @records_affected   INT = 0,
    @threshold          INT = 0,
    @details            NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit.data_quality_log (
        batch_id,
        check_name,
        layer,
        table_name,
        check_type,
        result_status,
        records_affected,
        threshold,
        details,
        check_timestamp
    )
    VALUES (
        @batch_id,
        @check_name,
        @layer,
        @table_name,
        @check_type,
        @result_status,
        @records_affected,
        @threshold,
        @details,
        SYSDATETIME()
    );

END;
GO
