/**********************************************************************************************
Description:
Notes:
- Prepping sql agent job script to run in auto load ETL mode
- This script checks if it is running on the correct server.
- It verifies the existence of the snapshot database.
- If the snapshot does not exist and the server is correct, it creates the snapshot.
- It tracks the creation time and usage duration of the snapshot.
- It alerts if the snapshot has been in use for more than 2 hours.
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
9/16/2026  William T          Initial creation of snapshot creation agent job script
9/16/2026  William T          idempotent - can run multiple times without error

**********************************************************************************************/


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
IF OBJECT_ID('tempdb..#CurrentSnapshot') IS NOT NULL DROP TABLE #CurrentSnapshot
IF OBJECT_ID('tempdb..#SnapshotOverLimit') IS NOT NULL DROP TABLE #SnapshotOverLimit

-- update 9/16
-- isCorrectServer
DECLARE @isCorrectServer bit;
declare @snapshotExists bit;

SELECT @@SERVERNAME AS ServerName
into #Results;

select @isCorrectServer = cast(iif(ServerName = 'SQL-VISUAL-2',1,0) as bit) from #Results;

-- check existence

IF EXISTS (
    SELECT 1 
    FROM sys.databases 
    WHERE name = 'VisualProdTmpSnp' 
      AND source_database_id IS NOT NULL
)
BEGIN
    PRINT 'Snapshot exists.';
    set @snapshotExists = 1;
END
ELSE
BEGIN
    PRINT 'Snapshot does not exist.';
    set @snapshotExists = 0;
END

-- if correct server AND not exists, create snapshot
IF @isCorrectServer = 1 AND @snapshotExists = 0
BEGIN
CREATE DATABASE VisualProdTmpSnp ON  
( NAME = NEWLIVE, FILENAME =   
'E:\SQLDATA\VisualProd.ss'),  
( NAME = NEWLIVE_CDC, FILENAME =   
'E:\SQLDATA\VisualProd2.ss')
AS SNAPSHOT OF LIVE;  

--DROP DATABASE VisualProdTmpSnp;



-- Remove after use  [create_date]

SELECT
    name AS SnapshotName,
	-- remove after use
    create_date AS CreationTime,  -- datetime
	-- remove after use
	datediff(hour,create_date, getdate()) hoursUsed,
    source_database_id,
    DB_NAME(source_database_id) AS SourceDatabaseName
    into #CurrentSnapshot
FROM
    sys.databases
WHERE 1=1
and source_database_id IS NOT NULL;

-- more than 2 hours ?
SELECT
    name AS SnapshotName,
	-- remove after use
    create_date AS CreationTime,  -- datetime
	-- remove after use
	datediff(hour,create_date, getdate()) hoursUsed,
    source_database_id,
    DB_NAME(source_database_id) AS SourceDatabaseName
    into #SnapshotOverLimit
FROM
    sys.databases
WHERE 1=1
and source_database_id IS NOT NULL
and datediff(hour,create_date, getdate()) > 2
END

-- clean up temp tables

IF OBJECT_ID('tempdb..#CurrentSnapshot') IS NOT NULL 
     -- if has records, print alert
     IF EXISTS (SELECT 1 FROM #CurrentSnapshot)
     BEGIN
         PRINT 'Current snapshot exists.';
     END
  
IF OBJECT_ID('tempdb..#SnapshotOverLimit') IS NOT NULL 
     -- if has records, print alert
     IF EXISTS (SELECT 1 FROM #SnapshotOverLimit)
     BEGIN
         PRINT 'Snapshot over limit exists.';
     END



