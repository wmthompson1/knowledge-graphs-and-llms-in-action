SET XACT_ABORT ON; -- Ensures the transaction is rolled back if a statement error occurs

DECLARE @TotalRecords INT;
DECLARE @DeletedRecords INT;
DECLARE @MaxDeleteAllowed INT;

-- 1. Get the total count of records in the target table
SELECT @TotalRecords = COUNT(*) FROM dbo.TargetTable;

-- Calculate the maximum number of deletions allowed (10%)
SET @MaxDeleteAllowed = CEILING(@TotalRecords * 0.10);

BEGIN TRANSACTION;

-- 2. Perform the MERGE operation with an OUTPUT clause to capture deleted rows
-- see Documentation\Schema\Data_Models\Work_Orders\Merge_Template\Create Merge Generator Section C.sql
-- <Section C Here>
    DELETE
OUTPUT $action, DELETED.PrimaryKey INTO @DeletedItems(ActionType, PrimaryKey); -- Capture deleted items into a temp table/variable

-- 3. Check the number of deleted records
SELECT @DeletedRecords = COUNT(*) FROM @DeletedItems WHERE ActionType = 'DELETE';

-- 4. Conditional commit or rollback
IF @DeletedRecords > @MaxDeleteAllowed
BEGIN
    PRINT 'Error: Attempted to delete more than 10% of records. Transaction rolled back.';
    ROLLBACK TRANSACTION;
END
ELSE
BEGIN
    PRINT 'Deletion count within limit. Transaction committed.';
    COMMIT TRANSACTION;
END

-- Clean up temporary table/variable if necessary
