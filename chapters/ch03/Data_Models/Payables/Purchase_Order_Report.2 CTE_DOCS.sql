--> HOME > VISUAL ENTERPRISE REPORTS > PURCHASING REPORTS > PURCHASE_ORDER
/**********************************************************************************************
Date     Modified By	Change Description
-------- -------------  ------------------------------------------------------------
20210909 tt				new version
20220211 mp				correction on logic to get document reference from EM's (didn't pull when legs were involved).  Spice Works Help Desk Ticket #1630
20260925 williamt        added Vendor Risk field to user defined fields pivot for VMVNDMNT


Purchase_Order_Report.1


**********************************************************************************************/

declare @ORDER_ID varchar(50) = '194174';   -- 194174  -- '194327'
declare @BASEID varchar(50) = '1817652';

IF OBJECT_ID('tempdb..#cte_docs') IS NOT NULL DROP TABLE #cte_docs


; WITH CTE_DOCS AS
--> MASTERS DOCS
(SELECT 

  'TEST' AS SRC 
   ,wo.PART_ID AS PART_ID
   ,wo.BASE_ID AS BASE_ID
   ,wo.LOT_ID AS LOT_ID
   ,wo.SPLIT_ID AS SPLIT_ID
   ,wo.SUB_ID AS SUB_ID
   ,wo.tYPE AS WORKORDER_TYPE
	--  DRW.WORKORDER_BASE_ID
	-- , DRW.WORKORDER_LOT_ID 
	-- , DRW.WORKORDER_SPLIT_ID
	-- , DRW.WORKORDER_SUB_ID
	-- , DRW.WORKORDER_TYPE
	-- , DRW.SEQUENCE_NO
	, WONUM = WO.BASE_ID + '/' + WO.LOT_ID + '/' + WO.SPLIT_ID + '/' + WO.SUB_ID
	, (SELECT D.ID + CASE
			WHEN D.REVISION_ID IS NULL THEN ' / REV: '
			ELSE ' / REV: ' + D.REVISION_ID
		END + CASE
			WHEN U1.STRING_VAL IS NULL THEN ' / ADCN: '
			ELSE ' / ADCN: ' + U1.STRING_VAL
		END + CHAR(10)
	) AS DOCUMENT_ID
-- FROM DEMAND_SUPPLY_LINK DSL
-- --> GIVES ME THE PART TO THE MASTER
-- INNER JOIN WORK_ORDER WO
FROM WORK_ORDER WO
	-- ON DSL.DEMAND_BASE_ID = WO.BASE_ID
	-- AND DSL.DEMAND_LOT_ID = WO.LOT_ID

	--AND WO.SUB_ID = '0'
left JOIN DOCUMENT_REF_WO DRW
	ON DRW.WORKORDER_BASE_ID = WO.PART_ID
	-- --DRW,WORKORDER_SUB_ID = DSL.DEMAND_SUB_ID)
	AND (DRW.WORKORDER_SUB_ID = WO.SUB_ID 
	--OR (DRW.WORKORDER_SUB_ID = 0 AND DRW.SEQUENCE_NO = 0)
	)
LEFT JOIN DOCUMENT D
	ON DRW.DOCUMENT_ID = D.ID
LEFT JOIN USER_DEF_FIELDS U1  --> ADCN
	ON D.ID = U1.DOCUMENT_ID
	AND U1.PROGRAM_ID = 'VMDOCMNT'
	AND U1.ID = 'UDF-0000032'
WHERE 1 = 1 --- ---DSL.SUPPLY_BASE_ID = @ORDER_ID
AND WO.BASE_ID = @BASEID
)
SELECT * 

FROM CTE_DOCS
