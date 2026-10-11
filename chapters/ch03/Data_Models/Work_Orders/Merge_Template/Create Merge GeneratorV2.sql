/*
    FINAL COMPLETE MERGE GENERATOR (ALL FIXES APPLIED)
*/

DECLARE
    @TableName SYSNAME = 'WODS_Comp_test223',
    @TableSchema SYSNAME = 'dbo',
    @SourceTable SYSNAME = 'WODS_Comp_test223',
    @SourceSchema SYSNAME = 'stage',
    @PrimaryKey NVARCHAR(MAX) = 'BASE_ID,LOT_ID,SPLIT_ID,SUB_ID';

-------------------------------------------------------
-- formatting variables (✅ required for STRING_AGG)
-------------------------------------------------------
DECLARE @CRLF NVARCHAR(2) = CHAR(13) + CHAR(10);

DECLARE @SepOR NVARCHAR(50)   = @CRLF + '    OR ';
DECLARE @SepAND NVARCHAR(50)  = @CRLF + '    AND ';
DECLARE @SepComma NVARCHAR(50)= ',' + @CRLF + '    ';

-------------------------------------------------------
-- validate tables exist
-------------------------------------------------------
IF OBJECT_ID(QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName), 'U') IS NULL
BEGIN
    THROW 50000, 'Target table does not exist.', 1;
END;

IF OBJECT_ID(QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable), 'U') IS NULL
BEGIN
    THROW 50000, 'Source table does not exist.', 1;
END;

-------------------------------------------------------
-- parse keys
-------------------------------------------------------
DECLARE @Keys TABLE (ColName SYSNAME);

INSERT INTO @Keys
SELECT TRIM(value)
FROM STRING_SPLIT(@PrimaryKey, ',');

-------------------------------------------------------
-- collect metadata
-------------------------------------------------------
IF OBJECT_ID('tempdb..#cols') IS NOT NULL DROP TABLE #cols;

SELECT 
    COLUMN_NAME,
    ORDINAL_POSITION,
    DATA_TYPE
INTO #cols
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @TableSchema
AND TABLE_NAME = @TableName;

-------------------------------------------------------
-- validate keys exist
-------------------------------------------------------
IF EXISTS (
    SELECT 1 
    FROM @Keys k
    LEFT JOIN #cols c ON k.ColName = c.COLUMN_NAME
    WHERE c.COLUMN_NAME IS NULL
)
BEGIN
    THROW 50000, 'One or more candidate keys not found in target table.', 1;
END;

-------------------------------------------------------
-- build JOIN
-------------------------------------------------------
DECLARE @Join NVARCHAR(MAX);

SELECT @Join =
STRING_AGG(
    CAST('trgt.' + QUOTENAME(ColName) + ' = src.' + QUOTENAME(ColName) AS NVARCHAR(MAX)),
    @SepAND
)
FROM @Keys;

-------------------------------------------------------
-- build MATCH (exclude keys)
-------------------------------------------------------
DECLARE @Match NVARCHAR(MAX);

SELECT @Match =
STRING_AGG(
CAST(
CASE 
    WHEN DATA_TYPE IN ('varchar','nvarchar','char','nchar','text')
        THEN 'ISNULL(trgt.' + QUOTENAME(COLUMN_NAME) + ', '''') <> ISNULL(src.' + QUOTENAME(COLUMN_NAME) + ', '''')'

    WHEN DATA_TYPE = 'tinyint'
        THEN 'ISNULL(trgt.' + QUOTENAME(COLUMN_NAME) + ', 0) <> ISNULL(src.' + QUOTENAME(COLUMN_NAME) + ', 0)'

    WHEN DATA_TYPE = 'smallint'
        THEN 'ISNULL(trgt.' + QUOTENAME(COLUMN_NAME) + ', -32768) <> ISNULL(src.' + QUOTENAME(COLUMN_NAME) + ', -32768)'

    WHEN DATA_TYPE IN ('int','bigint','decimal','numeric','float')
        THEN 'ISNULL(trgt.' + QUOTENAME(COLUMN_NAME) + ', -33000) <> ISNULL(src.' + QUOTENAME(COLUMN_NAME) + ', -33000)'

    WHEN DATA_TYPE IN ('date','datetime','datetime2','smalldatetime')
        THEN 'ISNULL(trgt.' + QUOTENAME(COLUMN_NAME) + ', ''19000101'') <> ISNULL(src.' + QUOTENAME(COLUMN_NAME) + ', ''19000101'')'

    WHEN DATA_TYPE = 'bit'
        THEN 'ISNULL(trgt.' + QUOTENAME(COLUMN_NAME) + ', 0) <> ISNULL(src.' + QUOTENAME(COLUMN_NAME) + ', 0)'

    ELSE 'trgt.' + QUOTENAME(COLUMN_NAME) + ' <> src.' + QUOTENAME(COLUMN_NAME)
END
AS NVARCHAR(MAX)),
@SepOR
)
FROM #cols
WHERE COLUMN_NAME NOT IN (SELECT ColName FROM @Keys);

-------------------------------------------------------
-- update set (exclude keys)
-------------------------------------------------------
DECLARE @UpdateSet NVARCHAR(MAX);

SELECT @UpdateSet =
STRING_AGG(
    CAST('trgt.' + QUOTENAME(COLUMN_NAME) + ' = src.' + QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)),
    @SepComma
)
FROM #cols
WHERE COLUMN_NAME NOT IN (SELECT ColName FROM @Keys);

-------------------------------------------------------
-- insert / values
-------------------------------------------------------
DECLARE @InsertCols NVARCHAR(MAX), @ValuesCols NVARCHAR(MAX);

SELECT 
    @InsertCols = STRING_AGG(CAST(QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), @SepComma),
    @ValuesCols = STRING_AGG(CAST('src.' + QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), @SepComma)
FROM #cols;

-------------------------------------------------------
-- assemble final MERGE
-------------------------------------------------------
DECLARE @SQL NVARCHAR(MAX) =

'SET XACT_ABORT ON;' + @CRLF + @CRLF +

'DECLARE   
    @TotalRows INT,
    @DeletedRows INT,
    @MaxDeleteAllowed INT;' + @CRLF + @CRLF +

'SELECT @TotalRows = COUNT(*) 
FROM ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ';' + @CRLF + @CRLF +

'SET @MaxDeleteAllowed = CEILING(@TotalRows * 0.10);' + @CRLF + @CRLF +

'DECLARE @MergeOutput TABLE
(
    ActionType NVARCHAR(10),
    KeyValue NVARCHAR(4000)
);' + @CRLF + @CRLF +

'BEGIN TRANSACTION;' + @CRLF + @CRLF +

'MERGE ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ' AS trgt
USING ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) + ' AS src
    ON ' + @Join + @CRLF + @CRLF +

'WHEN MATCHED AND
(
    ' + @Match + '
)
THEN UPDATE SET
    ' + @UpdateSet + @CRLF + @CRLF +

'WHEN NOT MATCHED BY TARGET THEN
INSERT
(
    ' + @InsertCols + '
)
VALUES
(
    ' + @ValuesCols + '
)' + @CRLF + @CRLF +

'WHEN NOT MATCHED BY SOURCE THEN DELETE' + @CRLF + @CRLF +

'OUTPUT $action, DELETED.' + QUOTENAME((SELECT TOP 1 ColName FROM @Keys)) + '
INTO @MergeOutput(ActionType, KeyValue);' + @CRLF + @CRLF +

'SELECT @DeletedRows = COUNT(*) FROM @MergeOutput WHERE ActionType = ''DELETE'';' + @CRLF + @CRLF +

'IF @DeletedRows > @MaxDeleteAllowed
BEGIN
    ROLLBACK;
    THROW 50001, ''MERGE aborted: excessive deletes detected.'', 1;
END
ELSE
BEGIN
    COMMIT;
END;';

-------------------------------------------------------
-- output full formatted SQL
-------------------------------------------------------
SET TEXTSIZE 2147483647;
SELECT @SQL AS GeneratedMerge;
--exec (@SQL);