USE [Master]

DECLARE @DBName VARCHAR(100);

SET @DBName = 'Convercent';

DECLARE @u TABLE
(
	[SPID] INT,
	[STATUS] VARCHAR(50),
	[Login] VARCHAR(100),
	[HostName] VARCHAR(100),
	[BlkBy] VARCHAR(10),
	[DBName] VARCHAR(100),
	[Command] VARCHAR(500),
	[CPUTime] VARCHAR(100),
	DiskIO VARCHAR(100),
	[LastBatch] VARCHAR(50),
	[ProgramName] VARCHAR(500),
	SPID2 INT,
	REQUESTID INT
)

INSERT INTO @u
exec sp_who2;

DECLARE @spids TABLE
(
    ident INT IDENTITY(1,1),
    [thespid] INT
)

INSERT INTO @spids ([thespid])
SELECT [spid] FROM @u WHERE DBName = @DBName;

select * from @spids

DECLARE @maxident INT;

DECLARE @currIdent INT;

DECLARE @currSpid INT;

SET @currIdent = 1;

SELECT @maxident = max(ident) FROM @spids;

WHILE @currIdent < @maxIdent
BEGIN
    SELECT @currSpid = [thespid] from @spids where ident = @currIdent

    PRINT 'Killing SPID ' + cast(@currSpid as varchar(10))

    DECLARE @exec VARCHAR(50)
    
    SET @exec = 'kill ' + cast(@currSpid as varchar(50))

    exec(@exec)

    SET @currIdent = @currIdent + 1
END