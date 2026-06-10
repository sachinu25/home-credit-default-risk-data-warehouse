USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: sp_log_etl_start
===============================================================================
Purpose:
    Logs the start of an ETL procedure execution.
    Returns a run_id to be used for subsequent logging calls.

Parameters:
    @procedure_name  - Name of the stored procedure being executed
    @layer           - Data warehouse layer (bronze, silver, gold)
    @table_name      - Target table being loaded
    @batch_id        - Optional batch identifier for grouping related loads
    @run_id          - OUTPUT: Generated run_id for tracking

Usage:
    DECLARE @run_id INT, @batch_id UNIQUEIDENTIFIER = NEWID();
    EXEC audit.sp_log_etl_start 
        @procedure_name = 'bronze.load_bronze',
        @layer = 'bronze',
        @table_name = 'application_train',
        @batch_id = @batch_id,
        @run_id = @run_id OUTPUT;
===============================================================================
*/

CREATE OR ALTER PROCEDURE audit.sp_log_etl_start
    @procedure_name     NVARCHAR(255),
    @layer              NVARCHAR(20),
    @table_name         NVARCHAR(255) = NULL,
    @batch_id           UNIQUEIDENTIFIER = NULL,
    @run_id             INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @batch_id IS NULL
        SET @batch_id = NEWID();

    INSERT INTO audit.etl_run_log (
        batch_id,
        procedure_name,
        layer,
        table_name,
        status,
        start_time
    )
    VALUES (
        @batch_id,
        @procedure_name,
        @layer,
        @table_name,
        'RUNNING',
        SYSDATETIME()
    );

    SET @run_id = SCOPE_IDENTITY();

END;
GO
