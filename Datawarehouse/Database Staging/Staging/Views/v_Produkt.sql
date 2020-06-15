CREATE VIEW [Staging].[v_Produkt]
	AS 
SELECT 
     a.[Product_Id]
	,a.[Product_Name]
	,a.[Meta_CreateJob] AS [Source_UpdateJob]
	,CAST ('Archive_Produkt' AS NVARCHAR) AS [Source_TableName]
	,s.[Department]
	,d.[Aisle]
FROM [Salg].[Archive].[Products] a
LEFT JOIN Salg.Archive.Departments s ON s.Department_Id = CAST(a.Department_Id AS SMALLINT)
	AND s.Meta_IsCurrent = 1
	AND s.Meta_IsDeleted = 0
LEFT JOIN Salg.Archive.Aisles d ON d.Aisle_Id = CAST(a.Aisle_Id AS SMALLINT)
	AND d.Meta_IsCurrent = 1
	AND d.Meta_IsDeleted = 0
WHERE a.Meta_IsCurrent = 1
	AND a.Meta_IsDeleted = 0
