USE [Database_Name];
GO

SET NOCOUNT ON;

DECLARE @v_BATCHSIZE INT
	,@v_WAITFORVAL VARCHAR(8)
	,@v_ITERATION INT
	,@v_TOTALROWS INT
	,@v_IterationMSG NVARCHAR(100)
	,@v_TOTALROWSMSG NVARCHAR(100)
	,@v_rc INT
	,@v_Initial_Delete NVARCHAR(100);

SET DEADLOCK_PRIORITY LOW;
SET @v_BATCHSIZE = 100000 --Change batch size to delete here. 
SET @v_WAITFORVAL = '00:00:05'
SET @v_rc = 1
SET @v_IterationMSG = 'Iteration: '
SET @v_TOTALROWSMSG = 'Total deletes:'
SET @v_ITERATION = 0
SET @v_TOTALROWS = 0
SET @v_Initial_Delete = 'Deleteme';

WHILE @v_rc > 0
BEGIN
	BEGIN TRANSACTION @v_Initial_Delete;

	BEGIN TRY
		DELETE TOP (@v_BATCHSIZE)
		FROM [Database_Name_Schema_Table_Name]
		WHERE --Relevant filter
			;

		SET @v_rc = @@ROWCOUNT;
	END TRY

	BEGIN CATCH
		SELECT ERROR_NUMBER() AS ErrorNumber
			,ERROR_SEVERITY() AS ErrorSeverity
			,ERROR_STATE() AS ErrorState
			,ERROR_PROCEDURE() AS ErrorProcedure
			,ERROR_LINE() AS ErrorLine
			,ERROR_MESSAGE() AS ErrorMessage;

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION @v_Initial_Delete;
	END CATCH;

	IF @@TRANCOUNT > 0
	BEGIN
		COMMIT TRANSACTION @v_Initial_Delete;

		-- CHECKPOINT;       -- if simple (optional)
		-- BACKUP LOG ... -- if full (optional)
		IF @v_rc = 0
			BREAK;

		SET @v_ITERATION = @v_ITERATION + 1
		SET @v_TOTALROWS = @v_TOTALROWS + @v_rc

		RAISERROR (
				'%s:%d'
				,0
				,1
				,@v_IterationMSG
				,@v_ITERATION
				)
		WITH NOWAIT;;

		RAISERROR (
				'%s:%d'
				,0
				,1
				,@v_TOTALROWSMSG
				,@v_TOTALROWS
				)
		WITH NOWAIT;;

		WAITFOR DELAY @v_WAITFORVAL;
	END
END
