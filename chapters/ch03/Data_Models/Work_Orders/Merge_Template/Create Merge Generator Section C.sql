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


SELECT 'Update_Where' = '	' + CASE 
	WHEN a.Nullable = 1 AND a.ColNo = 2 AND a.FinalType = 'smallint' AND stg.FinalType IN ('bit', 'tinyint') THEN '   ISNULL(trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END  + ' <> ISNULL(CONVERT(SMALLINT, src.' + stg.ColName + '), ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END 
	WHEN a.Nullable = 1 AND a.ColNo >= 3 AND a.FinalType = 'smallint' AND stg.FinalType IN ('bit', 'tinyint') THEN 'OR ISNULL(trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END  + ' <> ISNULL(CONVERT(SMALLINT, src.' + stg.ColName + '), ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END 
	WHEN a.Nullable = 1 AND a.ColNo = 2 THEN '   ISNULL(trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END  + ' <> ISNULL(src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END 
	WHEN a.Nullable = 1 AND a.ColNo >= 3 THEN 'OR ISNULL(trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END  + ' <> ISNULL(src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName) + ', ' + CASE WHEN a.FinalType IN ('smallint', 'int', 'bigint') THEN '-30000)' WHEN a.FinalType LIKE 'Decimal%' OR a.FinalType LIKE '%Numeric%' THEN '-30000)' WHEN a.FinalType = 'uniqueidentifier' THEN '''00000000-0000-0000-0000-000000000000'')' WHEN a.FinalType IN ('datetime', 'datetime2', 'smalldatetime', 'date') THEN '''1/1/1990'')' ELSE ''''')' END 
	WHEN a.ColNo = 2 THEN '   trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ' <> src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName)
	WHEN a.ColNo >= 3 THEN 'OR trgt.' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ' <> src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName)
	ELSE '' END
	, 'Update_Set' = '	' + CASE 
		WHEN a.ColNo = 2 THEN '  ' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ' = src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName)
		WHEN a.ColNo >= 2 THEN ', ' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) + ' = src.' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName)
		ELSE '' END
	, 'Insert' = CASE WHEN a.ColNo = 1 THEN '	( ' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) ELSE ', ' + IIF(a.ColName LIKE '% %', CONCAT('[', a.ColName, ']'), a.ColName) END
	, 'Values' = CASE WHEN stg.ColNo = 1 THEN '	( ' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName) ELSE ', ' + IIF(stg.ColName LIKE '% %', CONCAT('[', stg.ColName, ']'), stg.ColName) END
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
	--AND	c.COLUMN_NAME <> 'RowInsertDate'
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
