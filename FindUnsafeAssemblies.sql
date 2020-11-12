DECLARE @dbs TABLE
(
    ident int IDENTITY(1,1),
    dbname VARCHAR(128)
)

PRINT 'Trustworthy ON DB';

SELECT [name], is_trustworthy_on 
FROM sys.databases
WHERE is_trustworthy_on = 1
    AND [name] <> 'msdb';

INSERT INTO @dbs (dbname)
SELECT [name]
FROM sys.databases
SELECT name FROM sys.databases
WHERE is_trustworthy_on = 1 
    AND [name] <> 'msdb;'

IF OBJECT_ID('tempdb..#DBResults') IS NOT NULL
    DROP TABLE #DBResults;

IF OBJECT_ID('tempdb..#DBImpersonation') IS NOT NULL
    DROP TABLE #DBImpersonation;

CREATE TABLE #DBResults
(
    dbname VARCHAR(128),
    assemblyname VARCHAR(128),
    permissionset VARCHAR(128)
)

CREATE TABLE #DBImpersonation
(
    dbname VARCHAR(128),
    routinename VARCHAR(256),
    routinedefinition VARCHAR(MAX)
)

DECLARE @Statement VARCHAR(8000);

DECLARE @currCol VARCHAR(200);

DECLARE @currDb VARCHAR(200);

DECLARE @currIdent INT;

DECLARE @maxIdent INT;

SELECT @maxIdent = MAX(ident)
FROM @dbs;

SET @currIdent = 1;

WHILE @currIdent < @maxIdent
BEGIN
    SELECT @currDb = dbname FROM @dbs WHERE ident = @currIdent;

    SET @Statement = 'INSERT INTO #DBResults SELECT ''' + @currDb + ''', [Name], permission_set_desc FROM [' + @currDb + '].sys.assemblies WHERE [Name] <> ''Microsoft.SqlServer.Types'' AND permission_set_desc <> ''SAFE_ACCESS''';

    EXEC(@Statement);

    SET @Statement = 'INSERT INTO #DBImpersonation SELECT ''' + @currDb + ''', ROUTINE_NAME, ROUTINE_DEFINITION FROM [' + @currDb + '].INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_DEFINTION LIKE ''%EXECUTE AS%''';

    EXEC(@Statement);

    SET @currIdent = @currIdent + 1;
END

PRINT 'Databases with Unsafe Assemblies';

SELECT * FROM #DBResults;

PRINT 'Databases with EXECUTE AS Impersonation.  Investigate whether it is not EXECUTE AS CALLER.';

SELECT * FROM #DBImpersonation;

DROP TABLE #DBResults;

DROP TABLE #DBImpersonation;

