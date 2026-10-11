--> fragment 
/**********************************************************************************************
Date     Modified By	Change Description
-------- -------------  ------------------------------------------------------------
20260918 wt				added new logic for handling special document references.

our purchase order currently 'goes through' to the work order to grab any document:
`PURCHASE ORDER -> `DEMAND_SUPPLY_LINK` -> `DEMAND_BASE_ID`
-> `WORK_ORDER.BASE_ID/LOT_ID` -> `WORK_ORDER.PART_ID` -> `DOCUMENT_REF_WO.WORKORDER_BASE_ID`
-> `DOCUMENT`.

Resources:
KB1110312
https://customerportal.infor.com/csmcore?id=kb_article_view&sys_kb_id=920b0b62936bcad0678df2277bba1023

**********************************************************************************************/
DECLARE @ORDER_ID NVARCHAR(50) = '194174'  -- Replace 'PO' with the actual order ID you want to query
; WITH CTE_DOCS AS
--> MASTERS DOCS
(SELECT 'MASTERS' AS SRC 
	, DRW.WORKORDER_BASE_ID
	, DRW.WORKORDER_LOT_ID 
	, DRW.WORKORDER_SPLIT_ID
	, DRW.WORKORDER_SUB_ID
	, DRW.WORKORDER_TYPE
	, DRW.SEQUENCE_NO
	, (SELECT D.ID + CASE
			WHEN D.REVISION_ID IS NULL THEN ' / REV: '
			ELSE ' / REV: ' + D.REVISION_ID
		END + CASE
			WHEN U1.STRING_VAL IS NULL THEN ' / ADCN: '
			ELSE ' / ADCN: ' + U1.STRING_VAL
		END + CHAR(10)
	) AS DOCUMENT_ID
FROM DEMAND_SUPPLY_LINK DSL
--> GIVES ME THE PART TO THE MASTER
INNER JOIN WORK_ORDER WO
	ON DSL.DEMAND_BASE_ID = WO.BASE_ID
	AND DSL.DEMAND_LOT_ID = WO.LOT_ID
	AND WO.SUB_ID = '0'
INNER JOIN DOCUMENT_REF_WO DRW
	ON DRW.WORKORDER_BASE_ID = WO.PART_ID
	--DRW,WORKORDER_SUB_ID = DSL.DEMAND_SUB_ID)
	AND (DRW.WORKORDER_SUB_ID = DSL.DEMAND_SUB_ID 
    OR (DRW.WORKORDER_SUB_ID = 0 AND DRW.SEQUENCE_NO = 0))
INNER JOIN DOCUMENT D
	ON DRW.DOCUMENT_ID = D.ID
LEFT JOIN USER_DEF_FIELDS U1  --> ADCN
	ON D.ID = U1.DOCUMENT_ID
	AND U1.PROGRAM_ID = 'VMDOCMNT'
	AND U1.ID = 'UDF-0000032'
WHERE DSL.SUPPLY_BASE_ID = @ORDER_ID
)
Select *
From CTE_DOCS;

SELECT
    PO.ID AS PURCHASE_ORDER_ID,
    D.ID AS DOCUMENT_ID,
    D.CATEGORY_ID,
    D.DESCRIPTION,
    D.DOC_FILE_PATH,
    DR.SOURCE_TYPE,
FROM Live.dbo.PURCHASE_ORDER AS PO
JOIN Live.dbo.DOCUMENT_REFERENCE AS DR
    ON DR.ID = PO.ID
   AND DR.SOURCE_TYPE = N'R'
LEFT JOIN Live.dbo.DOCUMENT AS D
    ON D.ID = DR.DOCUMENT_ID
   AND D.SITE_ID = PO.SITE_ID;