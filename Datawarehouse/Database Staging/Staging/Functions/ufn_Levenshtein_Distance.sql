--- link til Levensthein funktionen http://blog.softwx.net/2014/12/optimizing-levenshtein-algorithm-in-tsql.html

CREATE FUNCTION [Staging].[ufn_Levenshtein_Distance] (
	@v_value_1 NVARCHAR(4000)-- Adressee for p_lokation_id1
	,@v_value_2 NVARCHAR(4000)-- Adressee for p_lokation_id
	,@max INT -- @max angiver om functionen skal stoppe ved et max antal af ændringer, i dette tilfælde er det ligegyldigt vi sætter derfor null
	)
RETURNS INT
	WITH SCHEMABINDING
AS
BEGIN
	DECLARE @resultat INT = 0 -- Denne variable angiver hvor mange ændringer der skal til for at de to adresser bliver lig med hinanden 
		,@v0 NVARCHAR(4000) -- running scratchpad for storing computed distances
		,@start INT = 1 -- index (1 based) of first non-matching character between the two string
		,@i INT
		,@j INT -- While loop tæller: i for s string and j for t string
		,@diag INT -- distance in cell diagonally above and left if we were using an m by n matrix
		,@left INT -- distance in cell to the left if we were using an m by n matrix
		,@sChar NCHAR -- character at index i from s string
		,@thisJ INT -- temporary storage of @j to allow SELECT combining
		,@jOffset INT -- offset used to calculate starting value for j loop
		,@jEnd INT -- ending value for j loop (stopping point for processing a column)
		-- get input string lengths including any trailing spaces (which SQL Server would otherwise ignore)
		,@laengdepaaString1 INT = datalength(@v_value_1) / datalength(left(left(@v_value_1, 1) + '.', 1)) -- Den total længde på den ene lokations adresse
		,@laengdepaaString2 INT = datalength(@v_value_2) / datalength(left(left(@v_value_2, 1) + '.', 1)) -- Den total længde på den anden lokations adresse
		,@lenDiff INT -- Differencen i længden mellem de to adressers dannet strings


	IF (@laengdepaaString1 > @laengdepaaString2) -- Dette er et step, der har til formål at forberede funktionen, i det tilfælde @laengdepaaString1 er større end @laengdepaaString2.
	BEGIN
		SELECT @v0 = @v_value_1
			,@i = @laengdepaaString1 -- temporarily use v0 for swap

		SELECT @v_value_1 = @v_value_2
			,@laengdepaaString1 = @laengdepaaString2

		SELECT @v_value_2 = @v0
			,@laengdepaaString2 = @i
	END

	SELECT @max = ISNULL(@max, @laengdepaaString2)
		,@lenDiff = @laengdepaaString2 - @laengdepaaString1

	IF @lenDiff > @max
		RETURN NULL

	-- suffix common to both strings can be ignored
	WHILE (
			@laengdepaaString1 > 0
			AND SUBSTRING(@v_value_1, @laengdepaaString1, 1) = SUBSTRING(@v_value_2, @laengdepaaString2, 1)
			)
		SELECT @laengdepaaString1 = @laengdepaaString1 - 1
			,@laengdepaaString2 = @laengdepaaString2 - 1

	IF (@laengdepaaString1 = 0)
		RETURN CASE 
				WHEN @laengdepaaString2 <= @max
					THEN @laengdepaaString2
				ELSE NULL
				END

	-- prefix common to both strings can be ignored
	WHILE (
			@start < @laengdepaaString1
			AND SUBSTRING(@v_value_1, @start, 1) = SUBSTRING(@v_value_2, @start, 1)
			)
		SELECT @start = @start + 1

	IF (@start > 1)
	BEGIN
		SELECT @laengdepaaString1 = @laengdepaaString1 - (@start - 1)
			,@laengdepaaString2 = @laengdepaaString2 - (@start - 1)

		-- if all of shorter string matches prefix and/or suffix of longer string, then
		-- edit distance is just the delete of additional characters present in longer string
		IF (@laengdepaaString1 <= 0)
			RETURN CASE 
					WHEN @laengdepaaString2 <= @max
						THEN @laengdepaaString2
					ELSE NULL
					END

		SELECT @v_value_1 = SUBSTRING(@v_value_1, @start, @laengdepaaString1)
			,@v_value_2 = SUBSTRING(@v_value_2, @start, @laengdepaaString2)
	END

	-- initialize v0 array of distances
	SELECT @v0 = ''
		,@j = 1

	WHILE (@j <= @laengdepaaString2)
	BEGIN
		SELECT @v0 = @v0 + NCHAR(CASE 
					WHEN @j > @max
						THEN @max
					ELSE @j
					END)

		SELECT @j = @j + 1
	END

	SELECT @jOffset = @max - @lenDiff
		,@i = 1

	WHILE (@i <= @laengdepaaString1)
	BEGIN
		SELECT @resultat = @i
			,@diag = @i - 1
			,@sChar = SUBSTRING(@v_value_1, @i, 1)
			-- no need to look beyond window of upper left diagonal (@i) + @max cells
			-- and the lower right diagonal (@i - @lenDiff) - @max cells
			,@j = CASE 
				WHEN @i <= @jOffset
					THEN 1
				ELSE @i - @jOffset
				END
			,@jEnd = CASE 
				WHEN @i + @max >= @laengdepaaString2
					THEN @laengdepaaString2
				ELSE @i + @max
				END

		WHILE (@j <= @jEnd)
		BEGIN
			-- at this point, @resultat holds the previous value (the cell above if we were using an m by n matrix)
			SELECT @left = UNICODE(SUBSTRING(@v0, @j, 1))
				,@thisJ = @j

			SELECT @resultat = CASE 
					WHEN (@sChar = SUBSTRING(@v_value_2, @j, 1))
						THEN @diag --match, no change
					ELSE 1 + CASE 
							WHEN @diag < @left
								AND @diag < @resultat
								THEN @diag --substitution
							WHEN @left < @resultat
								THEN @left -- insertion
							ELSE @resultat -- deletion
							END
					END

			SELECT @v0 = STUFF(@v0, @thisJ, 1, NCHAR(@resultat))
				,@diag = @left
				,@j = CASE 
					WHEN (@resultat > @max)
						AND (@thisJ = @i + @lenDiff)
						THEN @jEnd + 2
					ELSE @thisJ + 1
					END
		END

		SELECT @i = CASE 
				WHEN @j > @jEnd + 1
					THEN @laengdepaaString1 + 1
				ELSE @i + 1
				END
	END

	RETURN CASE  --Denne case when anvendes i det tilfælde at @max indeholder en værdi der er højere end de ændringer skal til for at begge ord bliver lig med hinanden vi sætter den altid til NULL. Det gør også at hvis @max er større end resultat, så sk
			WHEN @resultat <= @max
				THEN @resultat
			ELSE NULL
			END
END
GO

