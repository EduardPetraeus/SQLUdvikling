﻿CREATE PROCEDURE [Distribution].[sp_Get_Mapped_CPR]
@CPR_Nummer_Id INT

AS
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
	BEGIN TRANSACTION;

	SELECT DPEC.[CPR_Nummer]
	FROM [Distribution].[Personer_CPR_Nummer] DPEC
	INNER JOIN [Distribution].[Personer] DPE 
	ON DPE.CPR_Nummer_Id = DPEC.CPR_Nummer_Id
	
	WHERE DPEC.CPR_Nummer_Id = @CPR_Nummer_Id

	COMMIT TRANSACTION;
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

	THROW;
END CATCH;

GO
