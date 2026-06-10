USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: sp_log_etl_end
===============================================================================
Purpose:
    Logs the completion of an ETL procedure execution.
    Updates the run_id record with status, row count, and end time.
    Also updates the ETL metadata table with latest load information.

Parameters:
    @run_id          - The run_id from sp_log_etl_start
    @status          - Final status: 'SUCCESS' or 'FAILED'
    @rows_affected   - Number of rows processed
    @error_message   - Error message if status is FAILED

Usage:
    EXEC audit.sp_log_etl_end
        @run_id = @run_id,
        @status = 'SUCCESS',
        @rows_affected = @row_count;
===============================================================================
*/

CREATE OR ALTER PROCEDURE audit.sp_log_etl_end
    @run_id             INT,
    @status             NVARCHAR(20),
    @rows_affected      INT = NULL,
    @error_message      NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Update the ETL run log with completion details
    UPDATE audit.etl_run_log
    SET
        status          = @status,
        rows_affected   = @rows_affected,
        end_time        = SYSDATETIME(),
        error_message   = @error_message
    WHERE run_id = @run_id;

    -- If successful, update ETL metadata with latest load info
    IF @status = 'SUCCESS'
    BEGIN
        DECLARE @table_name NVARCHAR(255), @layer NVARCHAR(20);

        SELECT 
            @table_name = table_name,
            @layer = layer
        FROM audit.etl_run_log
        WHERE run_id = @run_id;

        IF @table_name IS NOT NULL
        BEGIN
            UPDATE audit.etl_metadata
            SET
                last_load_date  = SYSDATETIME(),
                row_count       = @rows_affected,
                modified_date   = SYSDATETIME()
            WHERE table_name = @table_name
              AND layer = @layer;
        END;
    END;

END;
GO
