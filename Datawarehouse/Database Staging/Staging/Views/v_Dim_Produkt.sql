CREATE VIEW [Staging].[v_Dim_Produkt]
	AS 
SELECT 
     a.[Product_Id]
	,a.[Product_Name]
	,s.[Department]
	,d.[Aisle]
FROM [Salg].[Archive].[Products] a
LEFT JOIN Salg.Archive.Departments s ON s.Department_Id = a.Department_Id
	AND s.Meta_IsCurrent = 1
	AND s.Meta_IsDeleted = 0
LEFT JOIN Salg.Archive.Aisles d ON d.Aisle_Id = a.Aisle_Id
	AND d.Meta_IsCurrent = 1
	AND d.Meta_IsDeleted = 0
WHERE a.Meta_IsCurrent = 1
	AND a.Meta_IsDeleted = 0
