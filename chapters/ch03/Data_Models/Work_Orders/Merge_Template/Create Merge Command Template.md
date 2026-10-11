# Create Merge Command Template

Purpose: generate a production-style MERGE statement from metadata, using the same comparison patterns seen in Work_Orders ETL merges.

## Inputs you set

- @TargetSchema, @TargetTable
- @SourceSchema, @SourceTable
- @KeyColumns as comma-separated list in join order
- @AllowDeletes and @MaxDeletePct guardrails

## Behavior

1. Builds ON clause from @KeyColumns.
2. Builds WHEN MATCHED AND comparison by data type:
   - string-like: ISNULL(trgt.col, '') <> ISNULL(src.col, '')
   - date/time: ISNULL(trgt.col, '19000101') <> ISNULL(src.col, '19000101')
   - numeric: ISNULL(trgt.col, -30000) <> ISNULL(src.col, -30000)
   - uniqueidentifier: ISNULL(CONVERT(nvarchar(36), trgt.col), '') <> ISNULL(CONVERT(nvarchar(36), src.col), '')
   - bit: ISNULL(CONVERT(tinyint, trgt.col), 255) <> ISNULL(CONVERT(tinyint, src.col), 255)
   - fallback: ISNULL(CONVERT(nvarchar(max), trgt.col), '') <> ISNULL(CONVERT(nvarchar(max), src.col), '')
3. Excludes key columns from UPDATE SET.
4. Includes all target columns in INSERT and VALUES.
5. Optionally adds delete guardrails with OUTPUT action counts.

## Template script

```sql
/*
Merge Generator Template
Based on Work_Orders patterns from SP_SK_ETL01_WS and usp_WODS_ETL01.
*/
SET NOCOUNT ON;

DECLARE
    @TargetSchema sysname = N'Staging',
    @TargetTable  sysname = N'WODS_Output_ETL',
    @SourceSchema sysname = N'Live',
    @SourceTable  sysname = N'OPERATION',
    @KeyColumns   nvarchar(max) = N'WONUM',
    @AllowDeletes bit = 1,
    @MaxDeletePct decimal(9,4) = 0.10;

DECLARE
    @CRLF nchar(2) = nchar(13) + nchar(10),
    @OnClause nvarchar(max) = N'',
    @MatchDiff nvarchar(max) = N'',
    @UpdateSet nvarchar(max) = N'',
    @InsertCols nvarchar(max) = N'',
    @InsertVals nvarchar(max) = N'',
    @Sql nvarchar(max) = N'';

IF OBJECT_ID('tempdb..#Keys') IS NOT NULL DROP TABLE #Keys;
CREATE TABLE #Keys
(
    KeyOrder int IDENTITY(1,1) PRIMARY KEY,
    ColName sysname NOT NULL
);

INSERT INTO #Keys (ColName)
SELECT LTRIM(RTRIM(value))
FROM STRING_SPLIT(@KeyColumns, ',')
WHERE LTRIM(RTRIM(value)) <> N'';

;WITH TargetCols AS
(
    SELECT
        c.column_id,
        c.name AS ColName,
        t.name AS TypeName,
        c.is_nullable,
        IsKey = CASE WHEN k.ColName IS NULL THEN 0 ELSE 1 END
    FROM sys.columns c
    JOIN sys.types t
      ON c.user_type_id = t.user_type_id
    LEFT JOIN #Keys k
      ON c.name = k.ColName
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@TargetSchema) + N'.' + QUOTENAME(@TargetTable))
)
SELECT
    @OnClause = STRING_AGG(N'trgt.' + QUOTENAME(k.ColName) + N' = src.' + QUOTENAME(k.ColName), N' AND ')
FROM #Keys k
JOIN TargetCols tc
  ON tc.ColName = k.ColName;

SELECT
    @InsertCols = STRING_AGG(QUOTENAME(tc.ColName), N', '),
    @InsertVals = STRING_AGG(N'src.' + QUOTENAME(tc.ColName), N', ')
FROM TargetCols tc;

;WITH Cols AS
(
    SELECT
        tc.column_id,
        tc.ColName,
        tc.TypeName,
        tc.IsKey,
        DiffExpr = CASE
            WHEN tc.IsKey = 1 THEN NULL
            WHEN tc.TypeName IN (N'char',N'nchar',N'varchar',N'nvarchar',N'text',N'ntext')
                THEN N'ISNULL(trgt.' + QUOTENAME(tc.ColName) + N', '''') <> ISNULL(src.' + QUOTENAME(tc.ColName) + N', '''')'
            WHEN tc.TypeName IN (N'date',N'datetime',N'datetime2',N'smalldatetime',N'datetimeoffset',N'time')
                THEN N'ISNULL(CONVERT(datetime2, trgt.' + QUOTENAME(tc.ColName) + N'), ''19000101'') <> ISNULL(CONVERT(datetime2, src.' + QUOTENAME(tc.ColName) + N'), ''19000101'')'
            WHEN tc.TypeName IN (N'tinyint',N'smallint',N'int',N'bigint',N'decimal',N'numeric',N'money',N'smallmoney',N'float',N'real')
                THEN N'ISNULL(trgt.' + QUOTENAME(tc.ColName) + N', -30000) <> ISNULL(src.' + QUOTENAME(tc.ColName) + N', -30000)'
            WHEN tc.TypeName = N'bit'
                THEN N'ISNULL(CONVERT(tinyint, trgt.' + QUOTENAME(tc.ColName) + N'), 255) <> ISNULL(CONVERT(tinyint, src.' + QUOTENAME(tc.ColName) + N'), 255)'
            WHEN tc.TypeName = N'uniqueidentifier'
                THEN N'ISNULL(CONVERT(nvarchar(36), trgt.' + QUOTENAME(tc.ColName) + N'), '''') <> ISNULL(CONVERT(nvarchar(36), src.' + QUOTENAME(tc.ColName) + N'), '''')'
            ELSE N'ISNULL(CONVERT(nvarchar(max), trgt.' + QUOTENAME(tc.ColName) + N'), '''') <> ISNULL(CONVERT(nvarchar(max), src.' + QUOTENAME(tc.ColName) + N'), '''')'
        END,
        SetExpr = CASE
            WHEN tc.IsKey = 1 THEN NULL
            ELSE QUOTENAME(tc.ColName) + N' = src.' + QUOTENAME(tc.ColName)
        END
    FROM TargetCols tc
)
SELECT
    @MatchDiff = STRING_AGG(DiffExpr, @CRLF + N' OR '),
    @UpdateSet = STRING_AGG(SetExpr, @CRLF + N' , ')
FROM Cols
WHERE DiffExpr IS NOT NULL;

IF @OnClause IS NULL OR @OnClause = N''
BEGIN
    THROW 50001, 'No key columns resolved. Set @KeyColumns.', 1;
END;

SET @Sql =
N'DECLARE @MergeResult TABLE(ActionTaken nvarchar(20) NOT NULL);' + @CRLF +
N'DECLARE @DeletedRows int = 0, @TotalRows int = 0;' + @CRLF +
N'' + @CRLF +
N'MERGE ' + QUOTENAME(@TargetSchema) + N'.' + QUOTENAME(@TargetTable) + N' trgt' + @CRLF +
N'USING ' + QUOTENAME(@SourceSchema) + N'.' + QUOTENAME(@SourceTable) + N' src WITH (NOLOCK)' + @CRLF +
N'ON ' + @OnClause + @CRLF +
N'' + @CRLF +
N'WHEN MATCHED AND ' + @CRLF + @MatchDiff + @CRLF +
N'THEN UPDATE SET' + @CRLF +
N'   ' + @UpdateSet + @CRLF +
N'' + @CRLF +
N'WHEN NOT MATCHED BY TARGET THEN' + @CRLF +
N'INSERT (' + @InsertCols + N')' + @CRLF +
N'VALUES (' + @InsertVals + N')' + @CRLF +
CASE WHEN @AllowDeletes = 1
    THEN N'WHEN NOT MATCHED BY SOURCE THEN DELETE' + @CRLF
    ELSE N'' END +
N'OUTPUT $action INTO @MergeResult(ActionTaken);' + @CRLF +
N'' + @CRLF +
N'SELECT @DeletedRows = COUNT(*) FROM @MergeResult WHERE ActionTaken = ''DELETE'';' + @CRLF +
N'SELECT @TotalRows = COUNT(*) FROM ' + QUOTENAME(@TargetSchema) + N'.' + QUOTENAME(@TargetTable) + N';' + @CRLF +
N'' + @CRLF +
N'IF ' + CONVERT(nvarchar(5), @AllowDeletes) + N' = 1 AND @TotalRows > 0 AND (CONVERT(decimal(19,6), @DeletedRows) / @TotalRows) > ' + CONVERT(nvarchar(30), @MaxDeletePct) + @CRLF +
N'BEGIN' + @CRLF +
N'    THROW 50002, ''Delete threshold exceeded for MERGE.'', 1;' + @CRLF +
N'END;' + @CRLF +
N'' + @CRLF +
N'SELECT ActionTaken, COUNT(*) AS RowCount FROM @MergeResult GROUP BY ActionTaken;';

SELECT @Sql AS GeneratedMergeScript;
-- EXEC sp_executesql @Sql; -- enable after review
```

## Notes

- Generator expects source and target to share column names.
- If names differ, create a source view that maps names to target.
- Keep @KeyColumns minimal and stable.
- For very large tables, consider batching and index validation before execution.
