CREATE VIEW [Staging].[v_Adresse_Koordinat]
	AS 

/*CTE to check if ekey exist in NoMatch and Koordinat table  */
WITH CTE_EKeyNoMatch AS (
SELECT Ekey_Adresse	AS EKey_Adresse
FROM Staging.Adresse_Koordinat

UNION

SELECT EKey_Adresse AS EKey_Adresse
FROM Staging.Adresse_NoMatch
)

SELECT
CAST(AA.Ekey_Adresse AS BIGINT) AS Ekey_Adresse,
CAST(AA.Vejnavn AS NVARCHAR(500)) AS Vejnavn,
CAST(AA.Husnummer AS NVARCHAR(46)) AS Husnummer,
CAST(AA.Postnummer AS SMALLINT) AS Postnummer 

FROM [Staging].[Adresse] AA
LEFT JOIN [Staging].[Adresse_Koordinat] SAK
	ON SAK.[Ekey_Adresse] = AA.[Ekey_Adresse]
WHERE NOT EXISTS (
            SELECT 1
            FROM CTE_EKeyNoMatch AS nkey --Join to check if keys exists from NoMatch/Koordinat table against Map table. 
            WHERE nkey.[EKey_Adresse] = AA.[Ekey_Adresse]
            )
OR (
	    AA.[Ekey_Adresse] = SAK.[Ekey_Adresse]
    AND AA.[Vejnavn] <> SAK.[Vejnavn]
    AND AA.[Husnummer] <> SAK.[Husnummer]
    AND AA.[Postnummer] <> SAK.[Postnummer]
    )