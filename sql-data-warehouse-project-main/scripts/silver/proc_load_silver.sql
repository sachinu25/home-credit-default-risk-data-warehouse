USE DataWarehouse;
GO

/*
===============================================================================
Stored Procedure: Load Complete Silver Layer
===============================================================================
Script Purpose:
    Executes all Silver layer load procedures in the correct order.

Execution Order:
    1. silver.load_application_train
    2. silver.load_application_test
    3. silver.load_bureau
    4. silver.load_previous_application
    5. silver.load_payments

Usage:
    EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY

        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Starting Silver Layer Load';
        PRINT '================================================';

        PRINT '>> Loading Application Train';
        EXEC silver.load_application_train;

        PRINT '>> Loading Application Test';
        EXEC silver.load_application_test;

        PRINT '>> Loading Bureau Tables';
        EXEC silver.load_bureau;

        PRINT '>> Loading Previous Application';
        EXEC silver.load_previous_application;

        PRINT '>> Loading Payment and Balance Tables';
        EXEC silver.load_payments;

        SET @batch_end_time = GETDATE();

        PRINT '================================================';
        PRINT 'Silver Layer Load Completed Successfully';
        PRINT 'Total Duration: ' 
              + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR)
              + ' seconds';
        PRINT '================================================';

    END TRY

    BEGIN CATCH

        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '================================================';

    END CATCH
END;
GO