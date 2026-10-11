/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
10/24/2025	William		interim legs released
05/05/2026 rm s and d
5/15 DUE DATE TEXT
6/4/2026 Added Cust_ECD and Revenue

(4501 rows affected)
Msg 207, Level 16, State 1, Line 62
Invalid column name 'Rank'.

-- status = 'U'
-- remaining_operations != 'No Remaining Operations'
-- is a leg
--    \__ denoted by dash subid: 1785750-1/1
--       \_and wonum like '%-%'
-- (4493 rows affected)
--select * into
--staging.dbo.WilliamTempVnext
--from #results

--select * from staging.dbo.WilliamTemp


**********************************************************************************************/

-- please make edits in the below sql that will determine why a work order with base_id 1664820 is not showing in the result. 
-- you can use declare @base_id = '1664820' and then filter on that variable in the relevant tables to debug. also, please 
-- check the labor_ticket table for any clock out records for that work order as that is a common reason for work orders to be 
-- filtered out of the result set.

declare @base_id nvarchar(50) = '1664820'

IF OBJECT_ID('tempdb..#Result1')IS NOT NULL DROP TABLE #Result1
IF OBJECT_ID('tempdb..#Result2')IS NOT NULL DROP TABLE #Result2
IF OBJECT_ID('tempdb..#Result3')IS NOT NULL DROP TABLE #Result3


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results


--USE DataWarehouse

/* WOs for patch with diferent CurrentOperation */
DECLARE @WOs varchar(48) = '1767423'

/* Main query original source WODs */
select --a.RM_READY, a.RESOURCE_ID, a.RLS_MT, 
	a.BASE_ID, a.LOT_ID, a.SPLIT_ID, a.SUB_ID, a.TYPE, a.PART_ID, a.WONUM, a.DESIRED_QTY, a.STATUS, a.CUSTOMER_ORDER, a.LINE_NO, a.CUSTOMER_ID, 
a.allocation_type, 
/* patch WO with diferent CurrentOperation (LabTicket put to zero in closed month) */
CASE WHEN BASE_ID in (@WOs) THEN c.SEQ_NO ELSE a.CurrentOperation
END as 'CurrentOperation',
a.StatusCurrOp, a.PRINTED_DATE, a.DESIRED_RLS_DATE, a.CREATE_DATE, a.remaining_operations, a.QTY_ON_HAND, 
a.QTY_IN_DEMAND, a.BUYER_USER_ID, a.PLANNER_USER_ID, a.COMMODITY_CODE, a.DESCRIPTION, a.DESIRED_WANT_DATE, a.[EXP/FLT], a.user_10, a.col_user_1, 
a.RWPart, a.CUSTOMER_PO_REF, a.WORK_ORDER_NOTES, a.CUST_ORDER_NOTATION, a.CUST_ORD_CREATEDATE, a.PartMaterialType, a.MaterialType, a.Alloy, 
a.CO_AMOUNT, a.UNIT_PRICE, a.TOTAL_AMT_SHIPPED, a.COL_AMOUNT, a.RESOURCE_ID_Raw, 
/* patch WO with diferent CurrentOperation (LabTicket put to zero in closed month) */
CASE WHEN BASE_ID = @WOs THEN c.OPERATION_TYPE ELSE a.OPERATION_TYPE
END as 'OPERATION_TYPE',
/* patch WO with diferent CurrentOperation (LabTicket put to zero in closed month) */
CASE WHEN BASE_ID in (@WOs) THEN c.SEQ_NO ELSE a.CURROPCHK
END as 'CURROPCHK',
CASE --WHEN BASE_ID = '1736167' THEN b.RESOURCE_ID 
	WHEN BASE_ID in (@WOs) THEN c.RESOURCE_ID ELSE a.RESOURCE_ID
END as 'RESOURCE_ID',
--a.OPERATION_TYPE, a.CURROPCHK, a.RESOURCE_ID, a.CurrentOperation, 
a.StatusCurrOpType, a.AubPriText, a.AubTcText, a.HasAubPri, a.HasAubTc, a.TimeLimit, a.LAST_CLOCK_OUT, a.last_worked_seq, a.last_clocked, a.LATE, a.LATEP2, a.LATEP1, 
a.LATEP3, a.LATEBP1, a.WAIT_DAYS, a.EMPLOYEE_ID, a.OPERATOR, a.USER_1, a.LEAD_SUPERVISOR, a.SupervisorName, a.StatusCurrOpMsg, a.tdesc, a.LABOR_TICKET_DESC, 
a.BUYER, a.BUYERFILTER, a.SALESREP_ID, a.Account, a.Plant_ID, a.Tooling, a.IsAP1, a.IsAP1a, a.IsAP2, a.IsAP2a, a.IsAP3, a.IsAP3a, a.IsBP1, a.IsUndetermined, 
a.IsNORGRU, a.IsTWMETA, a.IsAMTRIB, a.IsAUBMASK, a.IsAUBPrime, a.IsAUBSand, a.IsAUBsetup, a.IsAUBTC, a.IsAUBtakedown, a.IsAUBPartMark, a.IsAUBFinalInspection, 
a.IsAUBInspection, a.IsAUBPenetrant, a.IsAUBChemline, a.AP1_ETRAC, a.AP2_ETRAC, a.AP3_ETRAC, a.BP1_ETRAC, a.AP1_PDEXP, a.AP2_PDEXP, a.AP3_PDEXP, a.BP1_PDEXP, 
a.AP1_FLT, a.AP2_FLT, a.AP3_FLT, a.BP1_FLT, a.AP1_Buyer_Joe, a.AP1_Buyer_Rena, a.AP1_Buyer_Tiffany, a.AP1_Buyer_Sunni, a.AP1_Buyer_Danielle, a.AP1_Review, 
a.AP1_PlanningQueue, a.AP1_SkyFlex, a.ID, a.DESIRED_RECV_DATE, a.SnapshotDate, a.DEPARTMENT, a.SUB_DEPARTMENT, a.FACILITY, a.REPT_DEPT, a.PROCESS, a.REPORT_GROUPING, 
a.EMAIL_ADDR, a.SETUP_INFO, a.RLS_MT, a.RM_READY, a.remaining_operations_2, a.P1F1_RecibedWO_Date 
,sand_available
,a.RM_READYx
,a.cust_ecd
,a.revenue
into #Results
from [SQL-Lab-1].[LIVE].dbo.[WODS_Output_Complement] a
--from [SQL-Bi-1].[DataWarehouse].[dbo].[WODS_Output_Complement] a

/*join to patch WO with diferent CurrentOperation (LabTicket put to zero in closed month) */
left join ( SELECT WORKORDER_BASE_ID as 'WO', WORKORDER_LOT_ID as 'Lot', WORKORDER_SPLIT_ID as 'Split', RESOURCE_ID, SEQ_NO, OPERATION_TYPE 
	FROM [SQL-LAB-1].[LIVE].dbo.OPERATION O	(NOLOCK)
	inner join ( 
		SELECT min(SEQUENCE_NO) as 'SEQ_NO' FROM [SQL-LAB-1].[LIVE].dbo.OPERATION with (nolock) 
		WHERE WORKORDER_BASE_ID IN (@WOs) AND RUN_HRS > 0 and COMPLETED_QTY = 0 and status = 'R' and SEQUENCE_NO > 30
	) p on o.SEQUENCE_NO = p.SEQ_NO
	WHERE WORKORDER_BASE_ID IN (@WOs) AND WORKORDER_LOT_ID = '1' AND WORKORDER_SPLIT_ID = '0' 
	AND RUN_HRS > 0 and COMPLETED_QTY = 0 and status = 'R' 
	) c 
	ON a.BASE_ID = c.WO and a.LOT_ID = c.Lot 
	and a.SPLIT_ID = c.Split

--where a.RESOURCE_ID like 'P2M1-RLS%'
where a.BASE_ID = @base_id  
declare @rowCount1 int = @@ROWCOUNT
print 'Row count after initial WO pull: ' + CAST(@rowCount1 AS NVARCHAR(10))

SELECT [BASE_ID]
      ,[LOT_ID]
      ,[SPLIT_ID]
      ,[SUB_ID]
      ,[TYPE]
      ,[PART_ID]
      ,[WONUM]
      ,[DESIRED_QTY]
	 ,CASE WHEN w.status = 'U'
		and isnull(w.remaining_operations,'') != 'No Remaining Operations'
		and w.wonum like '%-%' THEN 'R'
		ELSE 
		w.[STATUS]
		END STATUS
      ,[CUSTOMER_ORDER]
      ,[LINE_NO]
      ,[CUSTOMER_ID]
      ,[allocation_type]
      ,[CurrentOperation]
      ,[StatusCurrOp]
      ,[PRINTED_DATE]
      ,[DESIRED_RLS_DATE]
      ,[CREATE_DATE]
      ,[remaining_operations]
      ,[QTY_ON_HAND]
      ,[QTY_IN_DEMAND]
      ,[BUYER_USER_ID]
      ,[PLANNER_USER_ID]
      ,[COMMODITY_CODE]
      ,[DESCRIPTION]
      ,[DESIRED_WANT_DATE]
	  
	  -- ssrs scales tablix
		,CASE 
			WHEN DESIRED_WANT_DATE IS NULL THEN ''
			ELSE CONVERT(VARCHAR(10), DESIRED_WANT_DATE, 1)  -- MM/DD/YY
		END AS DESIRED_WANT_DATE_TEXT

      ,[EXP/FLT]
      ,[user_10]
      ,[col_user_1]
      ,[RWPart]
      ,[CUSTOMER_PO_REF]
      ,[WORK_ORDER_NOTES]
      ,[CUST_ORDER_NOTATION]
      ,[CUST_ORD_CREATEDATE]
      ,[PartMaterialType]
      ,[MaterialType]
      ,[Alloy]
      ,[CO_AMOUNT]
      ,[UNIT_PRICE]
      ,[TOTAL_AMT_SHIPPED]
      ,[COL_AMOUNT]
      ,[RESOURCE_ID_Raw]
      ,[OPERATION_TYPE]
      ,[CURROPCHK]
      ,[RESOURCE_ID]
      ,[StatusCurrOpType]
      ,[AubPriText]
      ,[AubTcText]
      ,[HasAubPri]
      ,[HasAubTc]
      ,[TimeLimit]
      ,[LAST_CLOCK_OUT]
      ,[last_worked_seq]
      ,[last_clocked]
      ,[LATE]
      ,[LATEP2]
      ,[LATEP1]
      ,[LATEP3]
      ,[LATEBP1]
      ,[WAIT_DAYS]
      ,[EMPLOYEE_ID]
      ,[OPERATOR]
      ,[USER_1]
      ,[LEAD_SUPERVISOR]
      ,[SupervisorName]
      ,[StatusCurrOpMsg]
      ,[tdesc]
      ,[LABOR_TICKET_DESC]
      ,[BUYER]
      ,[BUYERFILTER]
      ,[SALESREP_ID]
      ,[Account]
      ,[Plant_ID]
      ,[Tooling]
      ,[IsAP1]
      ,[IsAP1a]
      ,[IsAP2]
      ,[IsAP2a]
      ,[IsAP3]
      ,[IsAP3a]
      ,[IsBP1]
      ,[IsUndetermined]
      ,[IsNORGRU]
      ,[IsTWMETA]
      ,[IsAMTRIB]
      ,[IsAUBMASK]
      ,[IsAUBPrime]
      ,[IsAUBSand]
      ,[IsAUBsetup]
      ,[IsAUBTC]
      ,[IsAUBtakedown]
      ,[IsAUBPartMark]
      ,[IsAUBFinalInspection]
      ,[IsAUBInspection]
      ,[IsAUBPenetrant]
      ,[IsAUBChemline]
      ,[AP1_ETRAC]
      ,[AP2_ETRAC]
      ,[AP3_ETRAC]
      ,[BP1_ETRAC]
      ,[AP1_PDEXP]
      ,[AP2_PDEXP]
      ,[AP3_PDEXP]
      ,[BP1_PDEXP]
      ,[AP1_FLT]
      ,[AP2_FLT]
      ,[AP3_FLT]
      ,[BP1_FLT]
      ,[AP1_Buyer_Joe]
      ,[AP1_Buyer_Rena]
      ,[AP1_Buyer_Tiffany]
      ,[AP1_Buyer_Sunni]
      ,[AP1_Buyer_Danielle]
      ,[AP1_Review]
      ,[AP1_PlanningQueue]
      ,[AP1_SkyFlex]
      ,[ID]
      ,[DESIRED_RECV_DATE]
      ,[SnapshotDate]
      ,[DEPARTMENT]
      ,[SUB_DEPARTMENT]
      ,[FACILITY]
      ,[REPT_DEPT]
      ,[PROCESS]
      ,[REPORT_GROUPING]
      ,[EMAIL_ADDR]
      ,[SETUP_INFO]
      ,[RLS_MT]
      ,[RM_READY]
      ,[remaining_operations_2]
      ,[P1F1_RecibedWO_Date]
      ,sand_available
      ,RM_READYx
      ,cust_ecd
    ,revenue
  FROM #results w
  where 1=1 