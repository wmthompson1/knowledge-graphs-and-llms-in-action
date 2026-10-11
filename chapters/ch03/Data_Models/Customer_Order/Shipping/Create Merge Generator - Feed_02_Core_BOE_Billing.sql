/*
    MERGE GENERATOR — LIVESupplemental.dbo.Feed_02_Core_BOE_Billing_stg (base table) --> LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
    Adapted from Documentation\Schema\Data_Models\Work_Orders\Merge_Template\Create Merge GeneratorV2.sql
    - Composite key support
    - Target and source both live in a different database (LIVESupplemental) than the current context
    - @AllowDeletes / @MaxDeletePct are configurable instead of hardcoded 10%
*/

DECLARE
    @TargetSchema sysname          = N'dbo',
    @TargetTable  sysname          = N'Feed_02_Core_BOE_Billing',
    @TargetDB     sysname          = N'LIVESupplemental',
    @SourceSchema sysname          = N'dbo',
    @SourceTable  sysname          = N'Feed_02_Core_BOE_Billing_stg',
    @SourceDB     sysname          = N'LIVESupplemental',
    @KeyColumns   nvarchar(max)    = N'CUST_ORDER_ID, COL_LINE_NO, PackSlip',
    @AllowDeletes bit              = 1,
    @MaxDeletePct decimal(9,4)     = 0.99;

-------------------------------------------------------
-- formatting helpers
-------------------------------------------------------
DECLARE @CRLF     NVARCHAR(2)  = CHAR(13) + CHAR(10);
DECLARE @SepOR    NVARCHAR(50) = @CRLF + '    OR ';
DECLARE @SepAND   NVARCHAR(50) = @CRLF + '    AND ';
DECLARE @SepComma NVARCHAR(50) = ',' + @CRLF + '    ';

-------------------------------------------------------
-- validate target and source exist (cross-database)
-------------------------------------------------------
DECLARE @TargetObjectId NVARCHAR(300) = QUOTENAME(@TargetDB) + '.' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable);
DECLARE @SourceObjectId NVARCHAR(300) = QUOTENAME(@SourceDB) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable);

IF OBJECT_ID(@TargetObjectId, 'U') IS NULL
BEGIN
    THROW 50000, 'Target table does not exist.', 1;
END;

IF OBJECT_ID(@SourceObjectId, 'U') IS NULL
BEGIN
    THROW 50000, 'Source table does not exist.', 1;
END;

-------------------------------------------------------
-- parse keys
-------------------------------------------------------
DECLARE @Keys TABLE (ColName SYSNAME);

INSERT INTO @Keys
SELECT TRIM(value)
FROM STRING_SPLIT(@KeyColumns, ',');

-------------------------------------------------------
-- collect target metadata (from the target database)
-------------------------------------------------------
IF OBJECT_ID('tempdb..#cols') IS NOT NULL DROP TABLE #cols;

DECLARE @MetaSql NVARCHAR(MAX) = N'
SELECT
    COLUMN_NAME,
    ORDINAL_POSITION,
    DATA_TYPE
FROM ' + QUOTENAME(@TargetDB) + '.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @TargetSchema
  AND TABLE_NAME   = @TargetTable;';

CREATE TABLE #cols (COLUMN_NAME sysname, ORDINAL_POSITION int, DATA_TYPE sysname);

INSERT INTO #cols
EXEC sp_executesql @MetaSql,
    N'@TargetSchema sysname, @TargetTable sysname',
    @TargetSchema = @TargetSchema, @TargetTable = @TargetTable;

-------------------------------------------------------
-- confirm the source table has the same columns
-------------------------------------------------------
IF OBJECT_ID('tempdb..#srccols') IS NOT NULL DROP TABLE #srccols;

DECLARE @SrcMetaSql NVARCHAR(MAX) = N'
SELECT COLUMN_NAME
FROM ' + QUOTENAME(@SourceDB) + '.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @SourceSchema
  AND TABLE_NAME   = @SourceTable;';

CREATE TABLE #srccols (COLUMN_NAME sysname);

INSERT INTO #srccols
EXEC sp_executesql @SrcMetaSql,
    N'@SourceSchema sysname, @SourceTable sysname',
    @SourceSchema = @SourceSchema, @SourceTable = @SourceTable;

IF EXISTS (
    SELECT 1
    FROM #cols c
    WHERE NOT EXISTS (
        SELECT 1
        FROM #srccols sc
        WHERE sc.COLUMN_NAME = c.COLUMN_NAME
    )
)
BEGIN
    THROW 50000, 'Source table is missing one or more target columns.', 1;
END;

-------------------------------------------------------
-- validate keys exist in target
-------------------------------------------------------
IF EXISTS (
    SELECT 1
    FROM @Keys k
    LEFT JOIN #cols c ON k.ColName = c.COLUMN_NAME
    WHERE c.COLUMN_NAME IS NULL
)
BEGIN
    THROW 50000, 'One or more key columns not found in target table.', 1;
END;

-------------------------------------------------------
-- build JOIN (composite key)
-------------------------------------------------------
DECLARE @Join NVARCHAR(MAX);

SELECT @Join =
STRING_AGG(
    CAST('trgt.' + QUOTENAME(ColName) + ' = src.' + QUOTENAME(ColName) AS NVARCHAR(MAX)),
    @SepAND
)
FROM @Keys;

-------------------------------------------------------
-- build MATCH condition (exclude keys)
-------------------------------------------------------
DECLARE @Match NVARCHAR(MAX);

SELECT @Match =
STRING_AGG(
CAST(
CASE
    WHEN DATA_TYPE IN ('varchar','nvarchar','char','nchar','text')
        THEN 'ISNULL(trgt.' + QUOTENAME(COLUMN_NAME) + ', N'''') <> ISNULL(src.' + QUOTENAME(COLUMN_NAME) + ', N'''')'

    WHEN DATA_TYPE = 'bit'
        THEN 'ISNULL(trgt.' + QUOTENAME(COLUMN_NAME) + ', 0) <> ISNULL(src.' + QUOTENAME(COLUMN_NAME) + ', 0)'

    WHEN DATA_TYPE IN ('int','bigint','smallint','tinyint','decimal','numeric','float')
        THEN 'ISNULL(trgt.' + QUOTENAME(COLUMN_NAME) + ', -999999) <> ISNULL(src.' + QUOTENAME(COLUMN_NAME) + ', -999999)'

    WHEN DATA_TYPE IN ('date','datetime','datetime2','smalldatetime')
        THEN 'ISNULL(trgt.' + QUOTENAME(COLUMN_NAME) + ', ''19000101'') <> ISNULL(src.' + QUOTENAME(COLUMN_NAME) + ', ''19000101'')'

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
-- insert / values (all columns)
-------------------------------------------------------
DECLARE @InsertCols NVARCHAR(MAX), @ValuesCols NVARCHAR(MAX);

SELECT
    @InsertCols = STRING_AGG(CAST(QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), @SepComma),
    @ValuesCols = STRING_AGG(CAST('src.' + QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), @SepComma)
FROM #cols;

-------------------------------------------------------
-- delete clause + safety check (only when @AllowDeletes = 1)
-------------------------------------------------------
DECLARE @DeleteClause NVARCHAR(MAX) = N'';
DECLARE @DeleteSafetyBlock NVARCHAR(MAX) = N'';
DECLARE @FirstKey sysname = (SELECT TOP 1 ColName FROM @Keys);

IF @AllowDeletes = 1
BEGIN
    SET @DeleteClause = @CRLF + @CRLF + 'WHEN NOT MATCHED BY SOURCE THEN DELETE';

    SET @DeleteSafetyBlock = @CRLF + @CRLF +
'SELECT @DeletedRows = COUNT(*) FROM @MergeOutput WHERE ActionType = ''DELETE'';' + @CRLF + @CRLF +
'IF @TotalRows > 0 AND (@DeletedRows * 1.0 / @TotalRows) > @MaxDeletePct
BEGIN
    ROLLBACK;
    THROW 50001, ''MERGE aborted: excessive deletes detected.'', 1;
END
ELSE
BEGIN
    COMMIT;
END;';
END
ELSE
BEGIN
    SET @DeleteSafetyBlock = @CRLF + @CRLF + 'COMMIT;';
END;

-------------------------------------------------------
-- assemble final MERGE
-------------------------------------------------------
DECLARE @SQL NVARCHAR(MAX) =

'SET XACT_ABORT ON;' + @CRLF + @CRLF +

'DECLARE
    @TotalRows INT,
    @DeletedRows INT = 0,
    @MaxDeletePct DECIMAL(9,4) = ' + CAST(@MaxDeletePct AS NVARCHAR(20)) + ';' + @CRLF + @CRLF +

'SELECT @TotalRows = COUNT(*)
FROM ' + QUOTENAME(@TargetDB) + '.' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ';' + @CRLF + @CRLF +

'DECLARE @MergeOutput TABLE
(
    ActionType NVARCHAR(10),
    KeyValue NVARCHAR(4000)
);' + @CRLF + @CRLF +

'BEGIN TRANSACTION;' + @CRLF + @CRLF +

'MERGE ' + QUOTENAME(@TargetDB) + '.' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ' AS trgt
USING ' + QUOTENAME(@SourceDB) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) + ' AS src
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
)' +

@DeleteClause + @CRLF + @CRLF +

'OUTPUT $action, CAST(DELETED.' + QUOTENAME(@FirstKey) + ' AS NVARCHAR(4000))
INTO @MergeOutput(ActionType, KeyValue);' +

@DeleteSafetyBlock;

-------------------------------------------------------
-- output generated SQL (review before executing)
-------------------------------------------------------
SET TEXTSIZE 2147483647;
SELECT @SQL AS GeneratedMerge;
print @SQL
--EXEC sp_executesql @SQL;
