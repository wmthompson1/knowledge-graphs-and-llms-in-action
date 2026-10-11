/**********************************************************************************************
Description:	Approved Supplier List
Sample:			

Date        Modified By         Change Description
----------  ------------------  ------------------------------------------------------------
8/28/2020	VME		Existing - Part I
8/28/2020	WMT		Added part2 to ASL
9/14/2020	WMT		Created ASL - Action Items report based on ASL
9/16/2020	WMT		Added year filter on 11 expiration columns
20210526	tt		Removed the garbage code; Updated to include new QC Notes from UDF, instead of Binary
20261001	wmt		Moved Vendor_ID/ApprovalStatus/ProductType/Buyer filters from Tablix to SQL using STRING_SPLIT

Find this section near the top of your query:

SELECT RTRIM(LTRIM(value)) AS Value INTO #Vendor_ID FROM STRING_SPLIT(@Vendor_ID, ',')
SELECT RTRIM(LTRIM(value)) AS Value INTO #ApprovalStatus FROM STRING_SPLIT(@ApprovalStatus, ',')
SELECT RTRIM(LTRIM(value)) AS Value INTO #ProductType FROM STRING_SPLIT(@ProductType, ',')
SELECT RTRIM(LTRIM(value)) AS Value INTO #Buyer FROM STRING_SPLIT(@Buyer, ',')

---
Replace it with this XML-based splitting approach (no version/compat dependency):

;WITH SplitVendor AS (
    SELECT RTRIM(LTRIM(Split.a.value('.', 'NVARCHAR(4000)'))) AS Value
    FROM (SELECT CAST('<x>' + REPLACE(@Vendor_ID, ',', '</x><x>') + '</x>' AS XML) AS xmlData) AS t
    CROSS APPLY xmlData.nodes('/x') AS Split(a)
)
SELECT Value INTO #Vendor_ID FROM SplitVendor WHERE Value <> ''

;WITH SplitApproval AS (
    SELECT RTRIM(LTRIM(Split.a.value('.', 'NVARCHAR(4000)'))) AS Value
    FROM (SELECT CAST('<x>' + REPLACE(@ApprovalStatus, ',', '</x><x>') + '</x>' AS XML) AS xmlData) AS t
    CROSS APPLY xmlData.nodes('/x') AS Split(a)
)
SELECT Value INTO #ApprovalStatus FROM SplitApproval WHERE Value <> ''

;WITH SplitProduct AS (
    SELECT RTRIM(LTRIM(Split.a.value('.', 'NVARCHAR(4000)'))) AS Value
    FROM (SELECT CAST('<x>' + REPLACE(@ProductType, ',', '</x><x>') + '</x>' AS XML) AS xmlData) AS t
    CROSS APPLY xmlData.nodes('/x') AS Split(a)
)
SELECT Value INTO #ProductType FROM SplitProduct WHERE Value <> ''

;WITH SplitBuyer AS (
    SELECT RTRIM(LTRIM(Split.a.value('.', 'NVARCHAR(4000)'))) AS Value
    FROM (SELECT CAST('<x>' + REPLACE(@Buyer, ',', '</x><x>') + '</x>' AS XML) AS xmlData) AS t
    CROSS APPLY xmlData.nodes('/x') AS Split(a)
)
SELECT Value INTO #Buyer FROM SplitBuyer WHERE Value <> ''


1.	Replace the 4 STRING_SPLIT blocks with the XML-based versions above.
2.	Paste the full updated query into the Dataset Properties → Query tab.
3.	Preview the report and test with multiple vendor/status/product/buyer selections.

*** error 2 ***

 this error (REPLACE requires 3 arguments) is a classic symptom of how SSRS binds
  parameters when using an OLE DB connection (common for your Live data source). OLE DB
   converts each @ParameterName into a positional ? placeholder, and it can get
    confused/misordered when the same named parameter is referenced inside an expression 
	like REPLACE(@Vendor_ID, ',', '</x><x>') rather than used as a plain standalone 
	value.

	##The fix: assign parameters to local variables first##

	Add this block right after your temp table cleanup (IF OBJECT_ID...DROP TABLE 
	statements) and before the XML split logic. Then reference the local variables 
	(not the raw @Parameter) inside the REPLACE/XML split calls.

	-- Bind SSRS parameters to local variables once (avoids OLE DB positional-parameter 
	-- binding issues)
DECLARE @Vendor_ID_local NVARCHAR(MAX) = ISNULL(@Vendor_ID, '')
DECLARE @ApprovalStatus_local NVARCHAR(MAX) = ISNULL(@ApprovalStatus, '')
DECLARE @ProductType_local NVARCHAR(MAX) = ISNULL(@ProductType, '')
DECLARE @Buyer_local NVARCHAR(MAX) = ISNULL(@Buyer, '')

Then update the four XML split CTEs to use the _local variables instead of the
 raw parameters:

 ;WITH SplitVendor AS (
    SELECT RTRIM(LTRIM(Split.a.value('.', 'NVARCHAR(4000)'))) AS Value
    FROM (SELECT CAST('<x>' + REPLACE(@Vendor_ID_local, ',', '</x><x>') + '</x>' AS XML) AS xmlData) AS t
    CROSS APPLY xmlData.nodes('/x') AS Split(a)
)
SELECT Value INTO #Vendor_ID FROM SplitVendor WHERE Value <> ''

;WITH SplitApproval AS (
    SELECT RTRIM(LTRIM(Split.a.value('.', 'NVARCHAR(4000)'))) AS Value
    FROM (SELECT CAST('<x>' + REPLACE(@ApprovalStatus_local, ',', '</x><x>') + '</x>' AS XML) AS xmlData) AS t
    CROSS APPLY xmlData.nodes('/x') AS Split(a)
)
SELECT Value INTO #ApprovalStatus FROM SplitApproval WHERE Value <> ''

;WITH SplitProduct AS (
    SELECT RTRIM(LTRIM(Split.a.value('.', 'NVARCHAR(4000)'))) AS Value
    FROM (SELECT CAST('<x>' + REPLACE(@ProductType_local, ',', '</x><x>') + '</x>' AS XML) AS xmlData) AS t
    CROSS APPLY xmlData.nodes('/x') AS Split(a)
)
SELECT Value INTO #ProductType FROM SplitProduct WHERE Value <> ''

;WITH SplitBuyer AS (
    SELECT RTRIM(LTRIM(Split.a.value('.', 'NVARCHAR(4000)'))) AS Value
    FROM (SELECT CAST('<x>' + REPLACE(@Buyer_local, ',', '</x><x>') + '</x>' AS XML) AS xmlData) AS t
    CROSS APPLY xmlData.nodes('/x') AS Split(a)
)
SELECT Value INTO #Buyer FROM SplitBuyer WHERE Value <> ''

**********************************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

IF OBJECT_ID('TEMPDB..#USER_DEF_FIELDS') IS NOT NULL DROP TABLE #USER_DEF_FIELDS
IF OBJECT_ID('TEMPDB..#USER_DEF_FIELDS_VENDOR_CERT') IS NOT NULL DROP TABLE #USER_DEF_FIELDS_VENDOR_CERT
IF OBJECT_ID('TEMPDB..#UDF_STRUCTURES') IS NOT NULL DROP TABLE #UDF_STRUCTURES
IF OBJECT_ID('TEMPDB..#VND_CERTS_KVPAIR_1') IS NOT NULL DROP TABLE #VND_CERTS_KVPAIR_1
IF OBJECT_ID('TEMPDB..#VND_CERTS_KVPAIR_2') IS NOT NULL DROP TABLE #VND_CERTS_KVPAIR_2
IF OBJECT_ID('TEMPDB..#VND_CERTS_KVPAIR_3') IS NOT NULL DROP TABLE #VND_CERTS_KVPAIR_3
IF OBJECT_ID('TEMPDB..#VND_CERTS_SCHEMA') IS NOT NULL DROP TABLE #VND_CERTS_SCHEMA
IF OBJECT_ID('TEMPDB..#VND_CERTS_DATA_FLAT') IS NOT NULL DROP TABLE #VND_CERTS_DATA_FLAT
IF OBJECT_ID('TEMPDB..#risk') IS NOT NULL DROP TABLE #risk

-- Split incoming multi-value parameters (comma-delimited strings from SSRS Join())
IF OBJECT_ID('TEMPDB..#Vendor_ID') IS NOT NULL DROP TABLE #Vendor_ID
IF OBJECT_ID('TEMPDB..#ApprovalStatus') IS NOT NULL DROP TABLE #ApprovalStatus
IF OBJECT_ID('TEMPDB..#ProductType') IS NOT NULL DROP TABLE #ProductType
IF OBJECT_ID('TEMPDB..#Buyer') IS NOT NULL DROP TABLE #Buyer

-- Bind SSRS parameters to local variables once (avoids OLE DB positional-parameter
-- binding issues) 
-- DECLARE @Vendor_ID NVARCHAR(MAX) = ISNULL('xxxxx', '')
-- DECLARE @ApprovalStatus NVARCHAR(MAX) = ISNULL('xxxx', '')
-- DECLARE @ProductType NVARCHAR(MAX) = ISNULL('xxxx', '')
-- DECLARE @Buyer NVARCHAR(MAX) = ISNULL('xxxx', '')

CREATE TABLE #risk
(
    [Vendor Risk] NVARCHAR(254),
    DOCUMENT_ID NVARCHAR(254)
)

INSERT INTO #risk
        select
                MAX(CASE WHEN ID = 'UDF-00118' THEN STRING_VAL END) AS [Vendor Risk]
				,DOCUMENT_ID
        FROM [LIVE].[dbo].[USER_DEF_FIELDS]
        WHERE PROGRAM_ID = 'VMVNDMNT'
            AND [LABEL] IS NULL
        GROUP BY DOCUMENT_ID




CREATE TABLE #VND_CERTS_SCHEMA
(PROGRAM_ID NVARCHAR(30), 
	ID NVARCHAR(30), 
	DOCUMENT_ID NVARCHAR(254), 
	[COMP EXP] DATETIME, 	
	[CP EXP] DATETIME, 	
	[HT EXP] DATETIME, 	
	[MTL EXP] DATETIME, 	
	[NDT EXP] DATETIME, 
	[SE EXP] DATETIME, 	
	[SLT EXP] DATETIME, 	
	[WLD EXP] DATETIME
)

CREATE TABLE #VND_CERTS_DATA_FLAT
(PROGRAM_ID NVARCHAR(30), 
	ID NVARCHAR(30), 
	DOCUMENT_ID NVARCHAR(254), 
	[COMP EXP] DATETIME, 	
	[CP EXP] DATETIME, 	
	[HT EXP] DATETIME, 	
	[MTL EXP] DATETIME, 	
	[NDT EXP] DATETIME, 
	[SE EXP] DATETIME, 	
	[SLT EXP] DATETIME, 	
	[WLD EXP] DATETIME
)

SELECT PUD0.*
INTO #USER_DEF_FIELDS
FROM USER_DEF_FIELDS PUD0 (NOLOCK)
WHERE (1=1)
AND RTRIM(LTRIM(PUD0.PROGRAM_ID)) IN (N'VMVNDMNT')
AND PUD0.DOCUMENT_ID IS NOT NULL
AND PUD0.ID IS NOT NULL

CREATE CLUSTERED INDEX CIDX_PUD ON #USER_DEF_FIELDS 
(DOCUMENT_ID
, ID 
, PROGRAM_ID 
)

SELECT PUD0.*
INTO #VND_CERTS_KVPAIR_1
FROM #USER_DEF_FIELDS PUD0
WHERE (1=1)
AND (PUD0.PROGRAM_ID IN ( N'VMVNDMNT'))
AND RTRIM(LTRIM(PUD0.ID)) IN ( 'UDF-0000093', 'UDF-0000094')

SELECT PUD0.*
INTO #VND_CERTS_KVPAIR_2
FROM #USER_DEF_FIELDS PUD0
WHERE (1=1)
AND (PUD0.PROGRAM_ID IN ( N'VMVNDMNT'))
AND RTRIM(LTRIM(PUD0.ID)) IN ( 'UDF-0000095', 'UDF-0000096')

SELECT PUD0.*
INTO #VND_CERTS_KVPAIR_3
FROM #USER_DEF_FIELDS PUD0
WHERE (1=1)
AND (PUD0.PROGRAM_ID IN ( N'VMVNDMNT'))
AND RTRIM(LTRIM(PUD0.ID)) IN ( 'UDF-0000097', 'UDF-0000098');

-- KEY VALUE PAIR (VENDOR CERT, EXPIRTION)
-- KV93_94
WITH CTE_KV_93_94 AS 
(SELECT KV1.PROGRAM_ID
	, 'X' AS ID
	, KV1.DOCUMENT_ID
	, KV1.STRING_VAL
	, KV2.DATE_VAL
FROM #VND_CERTS_KVPAIR_1 KV1
JOIN #VND_CERTS_KVPAIR_1 KV2
	ON KV1.PROGRAM_ID = KV2.PROGRAM_ID
	AND KV1.DOCUMENT_ID = KV2.DOCUMENT_ID
	AND KV1.ID = 'UDF-0000093'
	AND KV2.ID = 'UDF-0000094'
)
INSERT INTO #VND_CERTS_SCHEMA
SELECT PVT.*
FROM CTE_KV_93_94
PIVOT(MAX(DATE_VAL)
	FOR STRING_VAL IN ([COMP EXP], [CP EXP], [HT EXP], [MTL EXP], [NDT EXP], [SE EXP], [SLT EXP], [WLD EXP])
) PVT;

-- KEY VALUE PAIR (VENDOR CERT, EXPIRTION)
-- KV95_96
WITH CTE_KV_95_96 AS 
(SELECT KV1.PROGRAM_ID
	, 'X' AS ID
	, KV1.DOCUMENT_ID
	, KV1.STRING_VAL 
	, KV2.DATE_VAL 
FROM #VND_CERTS_KVPAIR_2 KV1
JOIN #VND_CERTS_KVPAIR_2 KV2
	ON KV1.PROGRAM_ID = KV2.PROGRAM_ID
	AND KV1.DOCUMENT_ID = KV2.DOCUMENT_ID
	AND RTRIM(LTRIM(KV1.ID)) = 'UDF-0000095'
	AND RTRIM(LTRIM(KV2.ID)) = 'UDF-0000096'
)

INSERT INTO #VND_CERTS_SCHEMA
SELECT PVT.*
FROM CTE_KV_95_96
PIVOT(MAX(DATE_VAL)
	FOR STRING_VAL IN ([COMP EXP], [CP EXP], [HT EXP], [MTL EXP], [NDT EXP], [SE EXP], [SLT EXP], [WLD EXP])
) PVT;

-- KEY VALUE PAIR (VENDOR CERT, EXPIRTION)
-- KV_97_98
WITH CTE_KV_97_98 AS 
(SELECT KV1.PROGRAM_ID
	, 'X' AS ID
	, KV1.DOCUMENT_ID
	, KV1.STRING_VAL
	, KV2.DATE_VAL
FROM #VND_CERTS_KVPAIR_3 KV1
JOIN #VND_CERTS_KVPAIR_3 KV2
	ON KV1.PROGRAM_ID = KV2.PROGRAM_ID
	AND KV1.DOCUMENT_ID = KV2.DOCUMENT_ID
	AND RTRIM(LTRIM(KV1.ID)) = 'UDF-0000097'
	AND RTRIM(LTRIM(KV2.ID)) = 'UDF-0000098'
)

INSERT INTO #VND_CERTS_SCHEMA
SELECT PVT.*
FROM CTE_KV_97_98
PIVOT(MAX(DATE_VAL)
	FOR STRING_VAL IN ([COMP EXP], [CP EXP], [HT EXP], [MTL EXP], [NDT EXP], [SE EXP], [SLT EXP], [WLD EXP])
) PVT

INSERT INTO #VND_CERTS_DATA_FLAT
SELECT [PROGRAM_ID]
	, [ID]
	, [DOCUMENT_ID]
	, [COMP EXP]	 	
	, [CP EXP]		
	, [HT EXP]		
	, [MTL EXP]		
	, [NDT EXP]		
	, [SE EXP]		
	, [SLT EXP]		
	, [WLD EXP]	
FROM (SELECT [PROGRAM_ID]
		, [ID]
		, [DOCUMENT_ID]
		, MAX([COMP EXP]) AS [COMP EXP]		 	
		, MAX([CP EXP]) AS [CP EXP]		
		, MAX([HT EXP]) AS [HT EXP]		
		, MAX([MTL EXP]) AS [MTL EXP]		
		, MAX([NDT EXP]) AS [NDT EXP]		
		, MAX([SE EXP]) AS [SE EXP]		
		, MAX([SLT EXP]) AS [SLT EXP]		
		, MAX([WLD EXP]) AS [WLD EXP]	
	FROM #VND_CERTS_SCHEMA
	GROUP BY [PROGRAM_ID]
		, [ID]
		, [DOCUMENT_ID]
	) X

SELECT V.ID AS VENDOR_ID
	, V.[NAME] AS VENDOR_NAME
	, V.OPEN_DATE AS ACCOUNT_OPENED
	, V.LAST_ORDER_DATE AS LAST_PO_DATE
	, V.USER_1 AS CONTROLLED_PRODUCT
	, V.USER_2 AS APPROVAL_STATUS
	, V.USER_3 AS APPROVAL_EXPIRATION_ON
	, V.USER_4 AS ITAR_EXPIRATION_ON
	, V.USER_5 AS DPD_EXPIRATION_ON
	, V.USER_6 AS SUPPLIER_TYPE
	, V.USER_7 AS PRODUCT_TYPE
	, V.USER_8 AS LIMITATIONS
	, UDF.STRING_VAL AS QCNOTES
	, CAST(CAST(VB.BITS AS VARBINARY(MAX)) AS NVARCHAR(MAX)) AS SPECIFICATIONS
	, V.CONTACT_FIRST_NAME + ' ' + V.CONTACT_LAST_NAME AS CONTACT_NAME
	, V.CONTACT_EMAIL AS EMAIL
	, V.CONTACT_PHONE AS DESK_PHONE
	, V.CONTACT_MOBILE AS CELL
	, V.ADDR_1 AS ADDRESS1
	, V.ADDR_2 AS ADDRESS2
	, V.CITY AS CITY
	, V.[STATE] AS [STATE]
	, V.ZIPCODE AS ZIP
	, V.BUYER
	, V.CONTACT_FIRST_NAME 
	, V.CONTACT_LAST_NAME
	, V.ACTIVE_FLAG
	, T.PROGRAM_ID
	, T.[COMP EXP] 
	, T.[CP EXP]
	, T.[HT EXP]
	, T.[MTL EXP]
	, T.[NDT EXP]
	, T.[SE EXP]
	, T.[SLT EXP]
	, T.[WLD EXP]
	, R.[Vendor Risk]
FROM VENDOR V
left join #risk R
	ON V.ID = R.DOCUMENT_ID
LEFT OUTER JOIN USER_DEF_FIELDS UDF
	ON UDF.PROGRAM_ID IN ( N'VMVNDMNT')
	AND UDF.ID IN ('UDF-0000102')
	AND UDF.DOCUMENT_ID = V.ID
LEFT OUTER JOIN VENDOR_BINARY VB
	ON V.ID = VB.VENDOR_ID
LEFT JOIN #VND_CERTS_DATA_FLAT T
ON V.ID = T.DOCUMENT_ID
WHERE V.ACTIVE_FLAG = 'Y'
	AND V.USER_1 = 'Y'
	AND V.ID IN (@Vendor_ID)
	AND (isnull(V.USER_2,'_blank')) IN (@ApprovalStatus)
	
	-- AND (
	-- 	V.USER_7 IN (@ProductType))
	
	---AND coalesce(V.BUYER,'_blank') IN (@Buyer)