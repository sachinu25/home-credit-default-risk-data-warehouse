USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: sp_log_error
===============================================================================
Purpose:
    Captures and logs detailed error information to the audit.etl_error_log
    table. Designed to be called from within CATCH blocks.

Parameters:
    @run_id   - The run_id from sp_log_etl_start (optional)
    @batch_id - The batch_id for correlation (optional)

Usage:
    BEGIN CATCH
        EXEC audit.sp_log_error @run_id = @run_id, @batch_id = @batch_id;
        THROW;
    END CATCH
===============================================================================
*/

CREATE OR ALTER PROCEDURE audit.sp_log_error
    @run_id             INT = NULL,
    @batch_id           UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit.etl_error_log (
        run_id,
        batch_id,
        error_number,
        error_severity,
        error_state,
        error_procedure,
        error_line,
        error_message,
        error_timestamp
    )
    VALUES (
        @run_id,
        @batch_id,
        ERROR_NUMBER(),
        ERROR_SEVERITY(),
        ERROR_STATE(),
        ERROR_PROCEDURE(),
        ERROR_LINE(),
        ERROR_MESSAGE(),
        SYSDATETIME()
    );

    -- Also update the ETL run log if run_id was provided
    IF @run_id IS NOT NULL
    BEGIN
        EXEC audit.sp_log_etl_end
            @run_id = @run_id,
            @status = 'FAILED',
            @error_message = 'See audit.etl_error_log for details';
    END;

END;
GO
