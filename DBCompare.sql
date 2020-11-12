DECLARE @currentDB varchar(30),
		@newDB varchar(30)

SET @currentDB = 'Warehouse2';

SET @newDB = 'Warehouse3';

EXEC ('USE ' + @currentDB);

DECLARE @compareSchemas TABLE (schemaname varchar(30));
DECLARE @joinColumns TABLE(colname varchar(50));
DECLARE @identityColumns TABLE(colname varchar(50), tablename varchar(50), schemaname varchar(30));

INSERT INTO @compareSchemas VALUES
	('ACL'),
	('Auth'),
	('Dimensions'),
	('DisclosureManagement'),
	('IssueManagement'),
	('OrganizationManagement')
;

INSERT INTO @joinColumns VALUES
	('IssueID'),
	('OrganizationID'),
	('ReportingPartyID'),
	('ObjectPropertyID'),
	('ReportedLocationID'),
	('OutcomeID'),
	('IssueTypeID'),
	('InvolvedPartiID'),
	('AllegationID'),
	('AccountID')
;

DECLARE @currTable varchar(50),
		@currSchema varchar(30),
		@currColumn varchar(50);

DECLARE @colSets TABLE (ident int identity(1,1), schemaname varchar(30), tablename varchar(50), colname varchar(50), datatype varchar(30), isidentity BIT);

INSERT INTO @colSets (schemaname, tablename, colname, datatype, isidentity)
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME, c.DATA_TYPE,
	COLUMNPROPERTY(object_id(c.TABLE_SCHEMA + '.' + c.TABLE_NAME), c.COLUMN_NAME, 'IsIdentity')
FROM INFORMATION_SCHEMA.Columns c
WHERE c.TABLE_SCHEMA IN (SELECT schemaname FROM @compareSchemas)
ORDER BY c.TABLE_SCHEMA, c.TABLE_NAME ASC;

INSERT INTO @identityColumns
SELECT colname, tablename, schemaname FROM @colSets
WHERE isidentity = 1;

DECLARE @currIdent INT, @maxIdent INT, @selectClause VARCHAR(8000), @whereClause VARCHAR(8000), @joinClause VARCHAR(8000), @complexJoinClause VARCHAR(8000), @compareClause VARCHAR(8000);
DECLARE @thisSchema VARCHAR(30), @thisTable VARCHAR(50), @thisColumn VARCHAR(50), @thisIsIdent BIT, @thisDataType VARCHAR(30);

SET @currIdent = 1;
SELECT @maxIdent = max(ident) from @colSets;

DECLARE @sqlStatements TABLE(sqlStatement varchar(max));

WHILE @currIdent <= @maxIdent
BEGIN
	SELECT @currSchema = schemaname, @thisSchema = schemaname, @currTable = tableName, @thistable = tablename, @thisColumn = colname, @thisIsIdent = isidentity FROM @colSets WHERE ident = @currIdent;
	
	SET @selectClause = 'SELECT * FROM ' + @currentDB + '.' + @currSchema + '.' + @currTable + ' AS t1 WITH (NOLOCK) ';
	SET @joinClause = ' INNER JOIN ' + @newDB + '.' + @currSchema + '.' + @currTable + ' AS t2 WITH (NOLOCK) ON ';
	SET @compareClause = ' WHERE ';
	SET @complexJoinClause = '';
	SET @whereClause = ' WHERE ';
	WHILE @thisSchema = @currSchema AND @thisTable = @currTable
	BEGIN
		IF EXISTS (SELECT colname from @joinColumns WHERE colname = @thisColumn)
		BEGIN
			SET @joinClause = @joinClause + 't1.' + @thisColumn + ' = t2.' + @thisColumn + ' ';
		END
		IF @thisIsIdent = 1 
		BEGIN
			
		END 
		ELSE
		BEGIN
			IF EXISTS (SELECT colname from @identityColumns WHERE colname = @thisColumn)
			BEGIN
				
			END
			ELSE
			BEGIN
				IF @whereClause <> ' WHERE ' 
				BEGIN
					SET @whereClause = @whereClause + ' AND ';
				END
				SET @whereClause = @whereClause + 't1.' + @thisColumn + ' <> t2.' + @thisColumn;
			END
		END
		SET @currIdent = @currIdent + 1;
		SELECT @thisSchema = schemaname, @thisTable = tablename, @thisColumn = colname, @thisIsIdent = isidentity FROM @colSets WHERE ident = @currIdent;
	END 
	INSERT INTO @sqlStatements VALUES (@selectClause + @joinClause + @complexJoinClause + @whereClause);
END