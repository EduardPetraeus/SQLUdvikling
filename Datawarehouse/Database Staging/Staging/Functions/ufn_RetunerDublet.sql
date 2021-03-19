CREATE FUNCTION [Staging].[ufn_RetunerDublet] (
      @adresseId1 INT,
      @adresseId2 INT	
)
RETURNS NVARCHAR(5)

AS
BEGIN

	DECLARE @v_value_1 NVARCHAR(4000),
	 @v_value_2 NVARCHAR(4000),
	 @laengste_adresse INT,
	 @Distance_ml_lokationer FLOAT(24)

	SELECT @v_value_1 = CONCAT (
			[DA].[Vejnavn]
			,'-'
			,[DA].[Husnummer]
			,'-'
			,[DA].[Postnummer]
			)
	FROM [Staging].[Adresse] [DA]
	WHERE Ekey_Adresse = @adresseId1


	-- Her dannes en string for master lokationens adresse
	SELECT @v_value_2 = CONCAT (
			[DA].[Vejnavn]
			,'-'
			,[DA].[Husnummer]
			,'-'
			,[DA].[Postnummer]
			)
	FROM [Staging].[Adresse] [DA]
	WHERE Ekey_Adresse = @adresseId2

	-- Avendes i @Similarity for at beregne procentmæssigt hvor tæt de to adresser er på hinanden
	SET @laengste_adresse = (
			SELECT CASE 
					WHEN len(@v_value_1) > len(@v_value_2)
						THEN len(@v_value_1)
					ELSE len(@v_value_2)
					END
			)
	-- Her anvendes Levenshtein funktionen, udgangspunktet for denne funktion er at kunne fortælle 
	--hvor mange ændringer der skal til for at to strings bliver ens. 
	--Dette omregner vi til en procentsat for bedre at kunne indikere om der er tale om en dublet.
	SET @Distance_ml_lokationer = (
			SELECT (cast([Distribution].[ufn_Levenshtein_Distance](UPPER(@v_value_1), UPPER(@v_value_2), 15) AS NUMERIC(18)) / @laengste_adresse * 100)
			)--))

			--select UPPER(@v_value_1)
			--select UPPER(@v_value_2)
			--SELECT @Distance_ml_lokationer

					RETURN (SELECT CASE 
					WHEN @Distance_ml_lokationer = 0 -- Hvis similarity funktionen er 0, så sættes vi et J, der indikerer at de er 100% identiske og altså en dublet
						THEN 'J'
					WHEN (
							@Distance_ml_lokationer >= 0.01 -- Hvis similarity funktionen er mellem 0.01 og 0.20, så er det kandidat
							AND @Distance_ml_lokationer <= 20
							)
						THEN 'K'
					ELSE 'N' -- hvis den er alt andet så er det ikke en dublet 
					END AS Dublet_JNK )
				END