CREATE FUNCTION [DMSA].[ufn_Find_Produkter_Købt_I_Ordre]
(
	@p_Product_Id INT 
)
RETURNS 
@Produkter TABLE
(
	[Ekey_Produkt]      INT           NOT NULL PRIMARY KEY,
	[Product_Id]        INT           NOT NULL,
	[Product_Name]      VARCHAR(100)  NULL,
	[Department]        NVARCHAR(30)  NULL,
	[Aisle]             NVARCHAR(50)  NULL

)
AS
    BEGIN
WITH CTE_Produkter AS (
	SELECT
	   [Ekey_Produkt]
      ,[Product_Id]
      ,[Product_Name]
      ,[Department]
      ,[Aisle]
	FROM [DMSA].[Dim_Produkt]
	WHERE [Product_Id] = @p_Product_Id -- BETWEEN DATEADD(YEAR, @p_Aar, GETDATE()) AND GETDATE() -- Kan bruges, hvis man vil hente ud baseret på tid

)
INSERT INTO @Produkter
SELECT
       [Ekey_Produkt]
      ,[Product_Id]
      ,[Product_Name]
      ,[Department]
      ,[Aisle]
FROM CTE_Produkter
    RETURN;
END
;