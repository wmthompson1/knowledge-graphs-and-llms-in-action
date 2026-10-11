/*
    FULL MERGE GENERATOR
    Produces:
    - Complete MERGE statement
    - WHEN MATCHED with generated comparisons
    - INSERT clause
    - DELETE with 10% safety enforcement
*/

DECLARE 
    @TargetSchema SYSNAME = 'dbo',
    @TargetTable  SYSNAME = 'TargetTable',
    @SourceSchema SYSNAME = 'dbo',
    @SourceTable  SYSNAME = 'SourceTable',
    @PrimaryKey   SYSNAME = 'PrimaryKey';   -- 🔴 REQUIRED

-------------------------------------------------------
-- 1. Collect metadata
-------------------------------------------------------
IF OBJECT_ID('tempdb..#cols') IS NOT NULL DROP TABLE #cols;

SELECT 
    c.ORDINAL_POSITION AS ColOrder,
    c.COLUMN_NAME      AS ColName,
    c.DATA_TYPE        AS DataType
INTO #cols
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_SCHEMA = @TargetSchema
  AND c.TABLE_NAME   = @TargetTable;

-------------------------------------------------------
-- 2. Build comparison logic (Section C preserved)
-------------------------------------------------------
DECLARE @MatchCondition NVARCHAR(MAX);
DECLARE @UpdateSet NVARCHAR(MAX);
DECLARE @InsertCols NVARCHAR(MAX);
DECLARE @ValuesCols NVARCHAR(MAX);

-- WHEN MATCHED condition
SELECT @MatchCondition =
    STRING_AGG(
        CASE 
            WHEN DataType IN ('varchar','nvarchar','char','nchar','text')
                THEN 'ISNULL(trgt.' + QUOTENAME(ColName) + ', '''') <> ISNULL(src.' + QUOTENAME(ColName) + ', '''')'

            WHEN DataType IN ('int','bigint','smallint','tinyint','decimal','numeric','float')
                THEN 'ISNULL(trgt.' + QUOTENAME(ColName) + ', -999999) <> ISNULL(src.' + QUOTENAME(ColName) + ', -999999)'

            WHEN DataType IN ('date','datetime','datetime2','smalldatetime')
                THEN 'ISNULL(trgt.' + QUOTENAME(ColName) + ', ''19000101'') <> ISNULL(src.' + QUOTENAME(ColName) + ', ''19000101'')'

            WHEN DataType = 'bit'
                THEN 'ISNULL(trgt.' + QUOTENAME(ColName) + ', 0) <> ISNULL(src.' + QUOTENAME(ColName) + ', 0)'

            ELSE 'trgt.' + QUOTENAME(ColName) + ' <> src.' + QUOTENAME(ColName)
        END,
        CHAR(10) + '    OR '
    )
FROM #cols
WHERE ColName <> @PrimaryKey;

-- UPDATE SET
SELECT @UpdateSet =
    STRING_AGG(
        'trgt.' + QUOTENAME(ColName) + ' = src.' + QUOTENAME(ColName),
        ',' + CHAR(10) + '    '
    )
FROM #cols
WHERE ColName <> @PrimaryKey;

-- INSERT + VALUES
SELECT 
    @InsertCols = STRING_AGG(QUOTENAME(ColName), ',' + CHAR(10) + '    '),
    @ValuesCols = STRING_AGG('src.' + QUOTENAME(ColName), ',' + CHAR(10) + '    ')
FROM #cols;

-------------------------------------------------------
-- 3. Build final script (Section D wrapper)
-------------------------------------------------------
DECLARE @SQL NVARCHAR(MAX) = '
SET XACT_ABORT ON;

DECLARE   
    @TotalRows        INT,
    @DeletedRows      INT,
    @MaxDeleteAllowed INT;

-- ✅ Row count
SELECT @TotalRows = COUNT(*) 
FROM ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ';

SET @MaxDeleteAllowed = CEILING(@TotalRows * 0.10);

-- ✅ Output tracking
DECLARE @MergeOutput TABLE
(
    ActionType NVARCHAR(10),
    KeyValue   NVARCHAR(4000)
);

BEGIN TRANSACTION;

MERGE ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ' AS trgt
USING ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) + ' AS src
    ON trgt.' + QUOTENAME(@PrimaryKey) + ' = src.' + QUOTENAME(@PrimaryKey) + '

-- ==========================================
-- ✅ WHEN MATCHED (ONLY WHEN CHANGED)
-- ==========================================
WHEN MATCHED AND
(
    ' + @MatchCondition + '
)
THEN UPDATE SET
    ' + @UpdateSet + '

-- ==========================================
-- ✅ INSERT
-- ==========================================
WHEN NOT MATCHED BY TARGET THEN
INSERT
(
    ' + @InsertCols + '
)
VALUES
(
    ' + @ValuesCols + '
)

-- ==========================================
-- ✅ DELETE
-- ==========================================
WHEN NOT MATCHED BY SOURCE THEN
DELETE

-- ==========================================
-- ✅ OUTPUT TRACKING
-- ==========================================
OUTPUT 
    $action,
    DELETED.' + QUOTENAME(@PrimaryKey) + '
INTO @MergeOutput(ActionType, KeyValue);

-- ==========================================
-- ✅ DELETE SAFETY CHECK
-- ==========================================
SELECT @DeletedRows = COUNT(*)
FROM @MergeOutput
WHERE ActionType = ''DELETE'';

IF @DeletedRows > @MaxDeleteAllowed
BEGIN
    ROLLBACK TRANSACTION;
    THROW 50001, ''MERGE aborted: excessive deletes detected.'', 1;
END
ELSE
BEGIN
    COMMIT TRANSACTION;
END;
';

-------------------------------------------------------
-- 4. Output
-------------------------------------------------------
PRINT @SQL;
--EXEC sp_executesql @SQL;
