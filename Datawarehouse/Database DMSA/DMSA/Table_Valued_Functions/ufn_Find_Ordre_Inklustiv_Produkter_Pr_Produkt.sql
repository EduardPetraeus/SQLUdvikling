CREATE FUNCTION [DMSA].[ufn_Find_Ordre_Inklustiv_Produkter_Pr_Produkt]
(
	@p_Product_Id INT 
)
RETURNS 
@Produkter TABLE
(   [Ekey_Kunde]               INT                           NOT NULL,
	[Order_Id]                 INT                           NOT NULL,
	[Eval_Set]                 NVARCHAR(20)                  NULL,
	[Order_Number]             SMALLINT                      NOT NULL,
	[Order_Dow]                SMALLINT                      NOT NULL,
	[Order_Hour_Of_Day]        SMALLINT                      NOT NULL,
	[Days_Since_Prior_Order]   DECIMAL(6,1)                  NULL,
	[Add_To_Cart_Order]        SMALLINT                      NOT NULL,
	[Reordered]                SMALLINT                      NOT NULL,
	[Ekey_Produkt]             INT                           NOT NULL,
	[Product_Id]               INT                           NOT NULL,
	[Product_Name]             VARCHAR(100)                  NULL,
	[Department]               NVARCHAR(30)                  NULL,
	[Aisle]                    NVARCHAR(50)                  NULL,
    [Meta_Id]                  INT IDENTITY(1,1) PRIMARY KEY NOT NULL

)
AS
    BEGIN
WITH CTE_Produkter AS (
SELECT 
       FO.[Ekey_Kunde]
      ,FO.[Order_Id]
      ,FO.[Eval_Set]
      ,FO.[Order_Number]
      ,FO.[Order_Dow]
      ,FO.[Order_Hour_Of_Day]
      ,FO.[Days_Since_Prior_Order]
      ,FO.[Add_To_Cart_Order]
      ,FO.[Reordered]
      ,FO.[Ekey_Produkt]
      ,U.Product_Id
      ,U.Product_Name
      ,U.Department
      ,U.Aisle
  FROM [DMSA].[ufn_Find_Produkter_Købt_I_Ordre] (@p_Product_Id) U  --Her joines table valued functions på med de relevante input parametre, antal år.
  INNER JOIN  [DMSA].[Fact_Ordre] FO  ON [FO].[Ekey_Produkt] = [U].[Ekey_Produkt]

)
INSERT INTO @Produkter
SELECT
       [Ekey_Kunde]
      ,[Order_Id]
      ,[Eval_Set]
      ,[Order_Number]
      ,[Order_Dow]
      ,[Order_Hour_Of_Day]
      ,[Days_Since_Prior_Order]
      ,[Add_To_Cart_Order]
      ,[Reordered]
      ,[Ekey_Produkt]
      ,[Product_Id]
      ,[Product_Name]
      ,[Department]
      ,[Aisle]
FROM CTE_Produkter
    RETURN;
END
;