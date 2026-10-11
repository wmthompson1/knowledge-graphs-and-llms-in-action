--Engineering
--ENGINE-DOCREF
--ENGINE-DOCREF-010.1-Document Ref.sql

-- use pivoted dataset to render data model for docxument reference.

-- VMDOCMNT
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;

SELECT
       1 AS CountOf
       , DOCUMENT_ID AS ID
    , MAX(CASE WHEN ID = 'UDF-0000031' THEN STRING_VAL ELSE NULL END) AS [Location]
    , MAX(CASE WHEN ID = 'UDF-0000032' THEN STRING_VAL ELSE NULL END) AS [ADCN]
    , MAX(CASE WHEN ID = 'UDF-0000033' THEN STRING_VAL ELSE NULL END) AS [Serial Number]
    , MAX(CASE WHEN ID = 'UDF-0000034' THEN STRING_VAL ELSE NULL END) AS [MFG Note]
    , MAX(CASE WHEN ID = 'UDF-0000050' THEN STRING_VAL ELSE NULL END) AS [Property]
    -- am I using the correct data type for ITAR Controlled?  It is a bit field, but I am using STRING_VAL.  Should I use BOOL_VAL instead?
    , MAX(CASE WHEN ID = 'UDF-0000051' THEN BOOL_VAL ELSE NULL END) AS [ITAR Controlled (Yes if checked)]
    , MAX(CASE WHEN ID = 'UDF-0000052' THEN STRING_VAL ELSE NULL END) AS [Status]
    , MAX(CASE WHEN ID = 'UDF-0000053' THEN STRING_VAL ELSE NULL END) AS [Received Date]
    , MAX(CASE WHEN ID = 'UDF-0000054' THEN STRING_VAL ELSE NULL END) AS [Stamped Revision]
    , MAX(CASE WHEN ID = 'UDF-0000055' THEN STRING_VAL ELSE NULL END) AS [Number of Pieces]
    , MAX(CASE WHEN ID = 'UDF-0000056' THEN STRING_VAL ELSE NULL END) AS [Usage Instructions]
    , MAX(CASE WHEN ID = 'UDF-0000057' THEN STRING_VAL ELSE NULL END) AS [AUTM]
    , MAX(CASE WHEN ID = 'UDF-0000058' THEN STRING_VAL ELSE NULL END) AS [Category]
    , MAX(CASE WHEN ID = 'UDF-0000059' THEN STRING_VAL ELSE NULL END) AS [Current Location]
INTO #Results
FROM Live.dbo.USER_DEF_FIELDS
WHERE PROGRAM_ID =  'VMDOCMNT' -- @PROGRAM_ID
AND DOCUMENT_ID IS NOT NULL
GROUP BY DOCUMENT_ID;
--SELECT * FROM #Results;


DECLARE @WOTYPE NVARCHAR(50) = ''
	, @CATEGORY NVARCHAR(50) = ''
	, @REVID NVARCHAR(50) = ''
--	, @BASEID NVARCHAR(50) = '214T3436-7003'
	, @BASEID NVARCHAR(50) = NULL

SELECT D.ID
	, D.[DESCRIPTION]
	, CASE 
		WHEN D.REFERENCE_TYPE =  'G' THEN 'GENERAL'
		ELSE 'LOOKUP'
	END AS REFERENCE_TYPE
	, D.CATEGORY_ID
	, D.REVISION_ID
	, CASE
		WHEN D.[DOC_FILE_PATH] = '-' THEN ''
		WHEN D.[DOC_FILE_PATH] = ' /' THEN ''
		WHEN D.[DOC_FILE_PATH] = '/' THEN ''
		WHEN D.[DOC_FILE_PATH] = '//' THEN ''
		WHEN D.[DOC_FILE_PATH] = '///' THEN ''
		WHEN D.[DOC_FILE_PATH] = '\\' THEN ''
		WHEN D.[DOC_FILE_PATH] = '\\\' THEN ''
		ELSE D.[DOC_FILE_PATH]
	END AS [DOC_FILE_PATH]
	, D.[STAGE_ID]
	, D.[USER_10]
	, D.[ALLOW_EMAIL]
	, D.[PATH_TYPE]
	, D.[ECN_REVISION]
	, D.[ECN_REV_CONTROL]
	-- , UDF31.STRING_VAL AS [Location]
	-- , UDF32.STRING_VAL AS [ADCN]
	-- , UDF33.STRING_VAL AS [Serial Number]
	-- , UDF34.STRING_VAL AS [MFG Note]
	-- , UDF50.STRING_VAL AS [Property]
    -- was the following valid? 
	-- , CASE
	-- 	WHEN UDF51.BOOL_VAL = '1' THEN 'YES'
	-- 	ELSE 'NO'
	-- END AS [ITAR Controlled]
	-- , UDF52.STRING_VAL AS [Status]
	-- , CASE
	-- 	WHEN UDF53.BOOL_VAL = '1' THEN 'YES'
	-- 	ELSE 'NO'
	-- END AS [Received Date]
	-- , UDF54.STRING_VAL AS [Stamped Revision]
	-- , UDF55.NUMBER_VAL AS [Number of Pieces]
	-- , UDF56.STRING_VAL AS [Usage Instructions]
	-- , UDF57.STRING_VAL AS [AUTM]
	-- , UDF58.STRING_VAL AS [Category]
	-- , UDF59.STRING_VAL AS [Current Location]
	, ISNULL(DRW.WORKORDER_TYPE, '-') AS WORKORDER_TYPE
	, DRW.WORKORDER_BASE_ID
	, DRW.WORKORDER_LOT_ID 
	, DRW.WORKORDER_SPLIT_ID
	, DRW.WORKORDER_SUB_ID
	, DRW.SEQUENCE_NO
	, DRW.PIECE_NO
 ,r.[Location]
 ,r.[ADCN]
 ,r.[Serial Number]
 ,r.[MFG Note]
 ,r.[Property]
 ,r.[ITAR Controlled (Yes if checked)]
 ,r.[Status]
 ,r.[Received Date]
 ,r.[Stamped Revision]
 ,r.[Number of Pieces]
 ,r.[Usage Instructions]
 ,r.[AUTM]
 ,r.[Category]
 ,r.[Current Location]  
FROM DOCUMENT D
LEFT OUTER JOIN DOCUMENT_REF_WO DRW
ON D.ID = DRW.DOCUMENT_ID 
left join #Results R
on D.ID = R.ID

-- LEFT OUTER JOIN USER_DEF_FIELDS UDF31
-- 	ON UDF31.[PROGRAM_ID] = 'VMDOCMNT'
-- 	AND D.ID = UDF31.DOCUMENT_ID
-- 	AND UDF31.ID = 'UDF-0000031'

-- LEFT OUTER JOIN USER_DEF_FIELDS UDF32
-- 	ON UDF32.[PROGRAM_ID] = 'VMDOCMNT'
-- 	AND D.ID = UDF32.DOCUMENT_ID
-- 	AND UDF32.ID = 'UDF-0000032'