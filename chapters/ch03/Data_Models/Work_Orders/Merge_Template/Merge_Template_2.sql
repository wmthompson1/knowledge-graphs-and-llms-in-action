SET XACT_ABORT ON;

DECLARE 
    @TotalRows        INT,
    @DeletedRows      INT,
    @MaxDeleteAllowed INT;

-- Optional safety check (recommended)
SELECT @TotalRows = COUNT(*) FROM dbo.TargetTable;
SET @MaxDeleteAllowed = CEILING(@TotalRows * 0.10);

DECLARE @MergeOutput TABLE
(
    ActionType NVARCHAR(10),
    KeyValue   INT -- adjust to PK datatype
);

BEGIN TRANSACTION;

MERGE dbo.TargetTable AS trgt
USING dbo.SourceTable AS src
    ON trgt.PrimaryKey = src.PrimaryKey  -- ✅ candidate key(s)

-- ==========================================
-- ✅ WHEN MATCHED (ONLY WHEN CHANGED)
-- ==========================================
WHEN MATCHED AND
(
       ISNULL(trgt.Col1, '') <> ISNULL(src.Col1, '')
    OR ISNULL(trgt.Col2, -999999) <> ISNULL(src.Col2, -999999)
    OR ISNULL(trgt.Col3, '19000101') <> ISNULL(src.Col3, '19000101')
    OR ISNULL(trgt.IsActive, 0) <> ISNULL(src.IsActive, 0)
)
THEN UPDATE SET
      trgt.Col1 = src.Col1
    , trgt.Col2 = src.Col2
    , trgt.Col3 = src.Col3
    , trgt.IsActive = src.IsActive

-- ==========================================
-- ✅ INSERT (FULL ROW)
-- ==========================================
WHEN NOT MATCHED BY TARGET THEN
INSERT
(
      PrimaryKey
    , Col1
    , Col2
    , Col3
    , IsActive
)
VALUES
(
      src.PrimaryKey
    , src.Col1
    , src.Col2
    , src.Col3
    , src.IsActive
)

-- ==========================================
-- ✅ DELETE (REQUIRED ADDITION)
-- ==========================================
WHEN NOT MATCHED BY SOURCE THEN
DELETE

-- ==========================================
-- ✅ OUTPUT TRACKING (SQL 2019 Safe Practice)
-- ==========================================
OUTPUT 
    $action,
    DELETED.PrimaryKey
INTO @MergeOutput(ActionType, KeyValue);

-- ==========================================
-- ✅ DELETE SAFETY VALIDATION
-- ==========================================
SELECT @DeletedRows = COUNT(*)
FROM @MergeOutput
WHERE ActionType = 'DELETE';

IF @DeletedRows > @MaxDeleteAllowed
BEGIN
    ROLLBACK TRANSACTION;
    THROW 50001, 'MERGE aborted: excessive deletes detected.', 1;
END
ELSE
BEGIN
    COMMIT TRANSACTION;
END