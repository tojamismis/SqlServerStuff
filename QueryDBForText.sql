DECLARE @textToFind NVARCHAR(4000)
DECLARE @Debug BIT
DECLARE @ColType VARCHAR(50)
DECLARE @FindExact BIT

SET @Debug = 0
SET @FindExact = 1
SET @textToFind = '@'
SET @ColType = 'UNIQUEIDENTIFIER'

SET NOCOUNT ON

DECLARE @tableCols TABLE
	(
		Ident INT IDENTITY(1,1),
		TableName NVARCHAR(200),
		ColName NVARCHAR(200)
	)

INSERT INTO @tableCols (TableName, ColName)
Select T.TABLE_SCHEMA + '.' + T.TABLE_NAME as 'TABLE', 
		C.COLUMN_NAME
from Information_Schema.Tables T
	INNER JOIN INFORMATION_SCHEMA.COLUMNS C
		on C.TABLE_NAME = T.TABLE_NAME
		and C.TABLE_SCHEMA = t.TABLE_SCHEMA
WHERE t.TABLE_TYPE <> 'VIEW'
AND T.TABLE_SCHEMA <> 'dbo'
AND C.DATA_TYPE = @ColType
AND C.COLUMN_NAME NOT IN ('CreatedBy', 'ModifiedBy')
AND c.CHARACTER_MAXIMUM_LENGTH < 1000
ORDER BY T.TABLE_SCHEMA, T.TABLE_NAME, C.ORDINAL_POSITION

DECLARE @Statement VARCHAR(8000)

DECLARE @currCol VARCHAR(200)

DECLARE @currTable VARCHAR(200)

DECLARE @currIdent INT

DECLARE @maxIdent INT

DECLARE @maxTableIdent INT

SELECT @maxIdent = MAX(Ident)
FROM @tableCols

SELECT @currIdent = 1

CREATE TABLE #Results
(
    TableName VARCHAR(100),
    ColName VARCHAR(100),
    Value NVARCHAR(MAX)
)

WHILE @currIdent < @maxIdent
BEGIN
	SELECT @currTable = TableName, @currCol = ColName FROM @tableCols WHERE Ident = @currIdent
	IF @Debug = 1
	BEGIN
		SELECT 'Working on ' + @currTable + ' and column ' + @currCol
	END

	IF @FindExact = 0
	BEGIN
		SET @Statement = 'INSERT INTO #Results SELECT ''' + @CurrTable + ''', ''' + @currCol + ''', [' + @currCol + '] FROM ' + @currTable + ' WITH (NOLOCK) WHERE [' + @currCol + '] LIKE ''%' + @textToFind + '%'''
	END
		ELSE
		BEGIN
			SET @Statement = 'INSERT INTO #Results SELECT ''' + @CurrTable + ''', ''' + @currCol + ''', [' + @currCol + '] FROM ' + @currTable + ' WITH (NOLOCK) WHERE [' + @currCol + '] = ''' + @textToFind + ''''
		END

	IF @Debug = 1
	BEGIN
		SELECT @Statement
	END

	EXEC( @Statement)

	SET @currIdent = @currIdent + 1
END 

SELECT TableName, ColName, Count(ColName) FROM #Results
GROUP BY TableName, ColName
ORDER BY 3 DESC, TableName, ColName

DROP TABLE #Results

SET NOCOUNT OFF