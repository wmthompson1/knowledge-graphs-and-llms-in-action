
Merge Template 
Section A. As an expert level SQL Developer, you prefer to structure a T-SQL Merge following the sample template in Section C. 
Section B. Preferred Structures in merge template: 
- prefer table to same table, staging to base table merge (schema is the same for source and target) 
- prefer source aliased as src, target aliased as trgt 
- prefer candidate keys join src to trgt 
when matched 
- prefer conditional match 

WHEN MATCHED AND trgt.BASE_ID <> src.BASE_ID OR trgt.LOT_ID <> src.LOT_ID 
OR trgt.SPLIT_ID <> src.SPLIT_ID OR trgt.SUB_ID <> src.SUB_ID 
OR trgt.TYPE <> src.TYPE OR ISNULL(trgt.PART_ID, '') <> ISNULL(src.PART_ID, '') 


- conditional match comparison is based on the field type. The field type impacts null handling 

String field handles null: 
OR ISNULL(trgt.PART_ID, '') <> ISNULL(src.PART_ID, '') 
Numeric field handles null with default -3000 - 30000:  
OR ISNULL(trgt.LINE_NO, -30000) <> ISNULL(src.LINE_NO, -30000) 
Date field handles null: 
OR ISNULL(trgt.DESIRED_RECV_DATE, '1/1/1990') <> ISNULL(src.DESIRED_RECV_DATE, '1/1/1990') 
Boolean field is literal:OR trgt.Is_Quality <> src.IsQuality
then update set 
Then Update Set Clause never updates candidate keys 
WHEN NOT MATCHED BY TARGET THEN INSERT
Insert list includes all targets including candidate keys, Values List includes all sources including candidate Keys
WHEN NOT MATCHED BY SOURCE Section (pending)
This portion requires the deletion to be less than 10%
This section of code is currently missing and needs to be updated
It is not possible to include a direct check within a statement in SQL Server that conditionally prevents a delete operation if it exceeds a certain percentage of total records. The clause does not support an additional clause that can perform complex lookups like a percentage calculation against the entire table. [1, 2, 3] 
To achieve this data integrity check, you must separate the deletion logic from the main statement and use an explicit transaction with conditional logic. 
Recommended Approach: Separate Logic within a Transaction 
The safest and most reliable method involves using a transaction to: 

Perform the operation, capturing the intended deletions using the clause into a temporary table. 
Check the count of intended deletions against the total record count in the target table. 
Either commit the transaction if the count is within the 10% limit or roll it back if it is not. [4]  

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
MERGE INTO dbo.TargetTable AS Target
USING dbo.SourceTable AS Source
    ON Target.PrimaryKey = Source.PrimaryKey
WHEN MATCHED THEN
    UPDATE SET Target.Column1 = Source.Column1 -- Example update
WHEN NOT MATCHED BY TARGET THEN
    INSERT (PrimaryKey, Column1) -- Example insert columns
    VALUES (Source.PrimaryKey, Source.Column1)
WHEN NOT MATCHED BY SOURCE THEN
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


First Draft To Be Improved
Section C. Sample Merge Command Code Template to be Improved

/* Create Merge Query Script 


Merge Template
Section A. As an expert level SQL Developer, you prefer to structure a T-SQL Merge following the sample template in Section C.
Section B. Preferred Structures in merge template:
 - prefer table to same table, staging to base table merge (schema is the same for source and target)
 - prefer source aliased as src, target aliased as trgt
 - prefer candidate keys join src to trgt
when matched
 - prefer conditional match

 Section_C_Follows



*/

Section_C_Follows:

declare
    @TableName sysname ,
    @TableSchema sysname,
    
    @SourceTable sysname,
    @SourceSchema SYSNAME

SET @SourceTable = 'WODS_Comp_test223';
SET @SourceSchema = 'dbo'

SET @Tablename = 'WODS_Comp_test223';
SET @TableSchema = 'dbo'


SELECT 'Update_Where' = '    ' + CASE 
    WHEN a.Nullable = 1 AND a.ColNo = 2 AND a.FinalType = 'smallint' AND stg.FinalType IN ('bit', 'tinyint') THEN '   ISNULL(trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END  + ' <> ISNULL(CONVERT(SMALLINT, src.' + stg.ColName + '), ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END 
    WHEN a.Nullable = 1 AND a.ColNo >= 3 AND a.FinalType = 'smallint' AND stg.FinalType IN ('bit', 'tinyint') THEN 'OR ISNULL(trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END  + ' <> ISNULL(CONVERT(SMALLINT, src.' + stg.ColName + '), ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END 
    WHEN a.Nullable = 1 AND a.ColNo = 2 THEN '   ISNULL(trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END  + ' <> ISNULL(src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END 
    WHEN a.Nullable = 1 AND a.ColNo >= 3 THEN 'OR ISNULL(trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END  + ' <> ISNULL(src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END 
    WHEN a.ColNo = 2 THEN '   trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ' <> src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName)
    WHEN a.ColNo >= 3 THEN 'OR trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ' <> src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName)
    ELSE '' END
    , 'Update_Set' = '    ' + CASE 
        WHEN a.ColNo = 2 THEN '  ' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ' = src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName)
        WHEN a.ColNo >= 2 THEN ', ' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ' = src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName)
        ELSE '' END
    , 'Insert' = CASE WHEN a.ColNo = 1 THEN '    ( ' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) ELSE ', ' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) END
    , 'Values' = CASE WHEN stg.ColNo = 1 THEN '    ( ' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName) ELSE ', ' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName) END
    , *
FROM 
    (
    SELECT 
        c.table_name ,
        column_name as ColName , 
        ordinal_position as ColNo ,
        data_type as DataType ,
        character_maximum_length as DataLen ,
        numeric_precision as Num_Prec ,
        numeric_scale as Num_Scale ,
        CASE is_nullable WHEN 'YES' THEN 1 ELSE 0 END as Nullable 
        , CASE WHEN data_type IS NULL THEN NULL
            WHEN data_type LIKE '%char%' OR data_type LIKE '%binary%' THEN data_type + ' (' + CONVERT(varchar, character_maximum_length) + ')'
            WHEN data_type IN ('numeric','decimal') THEN data_type + ' (' + CONVERT(varchar, numeric_precision) + ',' + CONVERT(varchar, numeric_Scale) + ')'
            ELSE data_type END as FinalType
        , SequentialOrder = ROW_NUMBER() OVER
            (PARTITION BY c.table_name
            ORDER BY c.ordinal_position)
    FROM information_schema.columns c (NOLOCK)
    JOIN INFORMATION_SCHEMA.TABLES t (NOLOCK)
        ON t.TABLE_NAME LIKE @Tablename
        AND t.TABLE_SCHEMA = @TableSchema
        AND t.TABLE_TYPE = 'BASE TABLE' -- Limits output to Real Tables only. Remove to include views.
        AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
        AND c.TABLE_NAME = t.TABLE_NAME
    WHERE (1=1)
    --AND    c.COLUMN_NAME <> 'RowInsertDate'
    --AND c.COLUMN_NAME <> 'RowUpdateDate'
        
        
        ) a
LEFT JOIN
    (SELECT 
        c.table_name ,
        column_name as ColName , 
        ordinal_position as ColNo ,
        data_type as DataType ,
        character_maximum_length as DataLen ,
        numeric_precision as Num_Prec ,
        numeric_scale as Num_Scale ,
        CASE is_nullable WHEN 'YES' THEN 1 ELSE 0 END as Nullable 
        , CASE WHEN data_type IS NULL THEN NULL
            WHEN data_type LIKE '%char%' OR data_type LIKE '%binary%' THEN data_type + ' (' + CONVERT(varchar, character_maximum_length) + ')'
            WHEN data_type IN ('numeric','decimal') THEN data_type + ' (' + CONVERT(varchar, numeric_precision) + ',' + CONVERT(varchar, numeric_Scale) + ')'
            ELSE data_type END as FinalType
    FROM information_schema.columns c (NOLOCK)
    JOIN INFORMATION_SCHEMA.TABLES t (NOLOCK)
        ON t.TABLE_NAME LIKE @SourceTable
        AND t.TABLE_SCHEMA = @SourceSchema
        AND t.TABLE_TYPE = 'BASE TABLE' -- Limits output to Real Tables only. Remove to include views.
        AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
        AND c.TABLE_NAME = t.TABLE_NAME
        
        ) stg
    ON a.SequentialOrder = stg.ColNo
ORDER BY a.ColNo;


