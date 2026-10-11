
-- C:\Users\williamt\OneDrive - Skills Inc GCC High\Documents\sql\20260622 Luke - Planning Daily Metrics\000 MEETING WITH SHANNEN.sql
/********
name of report: planning on time

ADVANCEDX DATE PAST WEEKEND

indiccated 

PLANNING METRICS
---------------------------
CMP  1
CMP P/D  2
POP    3
POP P/D   4
H/F CMP  5
REC INSP  6
FAI  7
H/F POP   8
POP FLT  9
POP FLT P/D   10
POP FLT H/F  11
REWORK   12

REQUIREMENTS
Prefer linked and unlinkeed orders for BOEPOP 

start_date = getlast_review_op_completed_close_date

LEGEND
   FLT (First Lot Testing) or First Article Testing (FAT) 
   EXP - Expedite
   H/F = Held for
   P/D - PAST DUE

Note - CMP is all linked.

not DESIRED_RLS_DATE
for start, use getlast_review_op_completed_close_date

select
    wonum
	,isnull(allocation_type,'Linked') allocation_type
	,customer_id
	,DESIRED_RLS_DATE
	,wo.status
	,WO.[getlast_review_op_completed_close_date] -- date of review op (is start for planning)
	, customer_id
	,[RM_READY]  --  NO if rm not avail
	,getdate() Today
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id = 'BOE609'
and wo.status = 'F'

TEMPLATE:

Select
  '00) METRIC' metric
  , Count(WO.Base_ID) countOf
   --, allocation_type, customer_id, WO.getlast_review_op_completed_close_date,rm_ready
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id = 'BOE609'
and wo.status = 'F'
---and getlast_review_op_completed_close_date <= dateadd(day,3,getdate())


**********/
/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------

**********************************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW;
IF OBJECT_ID('tempdb..#FAIResults') IS NOT NULL DROP TABLE #FAIResults;
IF OBJECT_ID('tempdb..#RevInsp') IS NOT NULL DROP TABLE #RevInsp;

-- now use
--dateadd(day,0,getdate()) <=  dateadd(day,x,DESIRED_RLS_DATE)

WITH CTE_WO AS
(
Select
  '07) FAI' note
  , Count(WO.Base_ID) countOf
  ,WO.BASE_ID, WO.LOT_ID, WO.SPLIT_ID, WO.SUB_ID, WO.[TYPE]
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id like '%'
and wo.status in ('U','F')
and wo.rm_ready ='NO'
AND dateadd(day,0,getdate()) <=  dateadd(day,0,DESIRED_RLS_DATE)
group by WO.BASE_ID, WO.LOT_ID, WO.SPLIT_ID, WO.SUB_ID, WO.[TYPE]

)
 ,CTE_USER_DEF_FIELDS_VMMFGWIN_WO AS (
    SELECT
        DOCUMENT_ID,
        MAX(CASE WHEN ID = 'UDF-0000086' THEN BOOL_VAL END)   AS [FAI Complete ?]
    FROM Live.dbo.USER_DEF_FIELDS
    WHERE PROGRAM_ID = 'VMMFGWIN_WO'
    AND [LABEL] IS NULL
    and ID IN ('UDF-0000086')
    and document_id like 'W%'
    GROUP BY DOCUMENT_ID


 )
SELECT 
    '07) FAI' note
  , Count(WO.Base_ID) countOf
    -- U1.[FAI Complete ?], WO.BASE_ID, WO.LOT_ID, WO.SPLIT_ID, WO.SUB_ID, WO.[TYPE]
    INTO #FAIResults
FROM CTE_WO Wo
LEFT OUTER JOIN CTE_USER_DEF_FIELDS_VMMFGWIN_WO U1
	ON U1.DOCUMENT_ID = N'W~' + Wo.BASE_ID + N'~' + Wo.SUB_ID + N'~' + Wo.LOT_ID + N'~' + Wo.SPLIT_ID  
WHERE Wo.TYPE='W'
and U1.[FAI Complete ?] = 1

/**********************************************************************************************
Description:  06 Inspection Review - count of work orders with review insp as first res
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
**********************************************************************************************/

SELECT 
       count(W.BASE_ID) countOf   

     into #RevInsp
 FROM [dbo].[SKILLS_WO_OPS_first_last_loc] w
 INNER JOIN PART P
    ON P.ID = W.PART_ID
  WHERE w.FirstRES like 'reviewInsp'

-- 1  CMP
----


Select
  '01) CMP' note
  , Count(WO.Base_ID) countOf
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id = 'BOE609'
and wo.status = 'F'
UNION ALL

--2  CMP P/D
-- today is june 3, so anything start date +3 is late (3 business days), like June 6
-- work order count
-- add the sec for pd 
-- start = rel date - 3 ;  11/26/2025 | 002020047 
-- DESIRED_RLS_DATE

Select
  '02) CMP P/D' note
  , Count(WO.Base_ID) countOf
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id = 'BOE609'
and wo.status = 'f'
AND dateadd(day,0,getdate()) <=  dateadd(day,4,DESIRED_RLS_DATE)


--3  POP
------
UNION ALL

Select
  '03) POP' note
  , Count(WO.Base_ID) countOf
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id = 'BOEPOP'
and wo.status = 'f'
-- ** 

union all
--4  POP P/D
---------
Select
  '04) POP P/D' note
  , Count(WO.Base_ID) countOf
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id = 'BOEPOP'
and wo.status = 'f'
AND dateadd(day,0,getdate()) <=  dateadd(day,7,DESIRED_RLS_DATE)

-- 5  H/F CMP
  -- H/F CMP - held for cmp
       -- cmp Unreleased no material
	   -- start date of today or older (start = rel date)
union all 

Select
  '05) H/F CMP' note
  , Count(WO.Base_ID) countOf
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id = 'BOE609'
and wo.status = 'U'


union all 
--6  REC Insp
--table this)
--  two inspct
--  review, op, review


--      * what's in queue for review?  (2nd op)
select '06) TBD--Inspct. =>' note, countof
from #RevInsp
-- see folder for details
-- 1 move is created
-- 2 op is completed
-- 3 2nd barcode - would this be a 2nd review?  or is it a 2nd op?  (2nd op)
   

--7  FAI
-- All unreleased + firmed; that have start date today and older
--   and all jobs no material
--   caveat - HAVE to be fai orders
union all

--Select
--  '07) FAI' note
--  , Count(WO.Base_ID) countOf
--   --, allocation_type, customer_id, WO.getlast_review_op_completed_close_date,rm_ready
--from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
--WHERE customer_id like '%'
--and wo.status in ('U','F')
--and wo.rm_ready ='NO'
--and getlast_review_op_completed_close_date <= dateadd(day,0,getdate())

-- ~22
    SELECT * FROM #FAIResults
-- ~22
 
--8  H/F POP
union all

--Select
--Count(WO.Base_ID)
--from Work_Order WO
--Left Outer Join Demand_Supply_Link DSL
--on DSL.SUPPLY_BASE_ID = WO.BASE_ID
--and DSL.SUPPLY_LOT_ID = WO.LOT_ID
--and DSL.SUPPLY_SPLIT_ID = WO.SPLIT_ID
--and DSL.SUPPLY_SUB_ID = WO.SUB_ID
--Left Outer Join CUST_ORDER_LINE COL
--on COL.Cust_Order_ID = DSL.Demand_Base_ID
--and COL.Line_No = DSL.Demand_Seq_No
--Left Outer Join CUSTOMER_ORDER CO
--on CO.ID = COL.Cust_Order_ID
--Where WO.[TYPE] = 'W'
--and WO.[STATUS] = 'U'
--and CO.Customer_ID = 'BOEPOP'
--and DSL.SUPPLY_BASE_ID is null

Select
  '08) H/F POP' note
  , Count(WO.Base_ID) countOf
   --, allocation_type, customer_id, WO.getlast_review_op_completed_close_date,rm_ready
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id like 'BOEPOP'
and wo.status in ('U')

 
union all 
--9  POP FLT
-- BOEPOP FLT DESIGNATION  unreleased
-- see H/F POP  (firm, flt)
  --above + start date of today or older

  Select
  '09) POP FLT' note
  , Count(WO.Base_ID) countOf
   --, allocation_type, customer_id, WO.getlast_review_op_completed_close_date,rm_ready
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id like 'BOEPOP'
and wo.status in ('F')
and [EXP/FLT] = '5_FLT'


 union all
--10  POP FLT P/D
  --above + start date of today or older
Select
  '10) POP FLT P/D' note
  , Count(WO.Base_ID) countOf
   --, allocation_type, customer_id, WO.getlast_review_op_completed_close_date,rm_ready
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id like 'BOEPOP'
and wo.status in ('F')
and [EXP/FLT] = '5_FLT'
--and getlast_review_op_completed_close_date <= dateadd(day,0,getdate())
--AND dateadd(day,0,getdate()) <= DESIRED_RLS_DATE
AND dateadd(day,0,getdate()) <=  dateadd(day,7,DESIRED_RLS_DATE)

union all
--11  POP FLT H/F
--(H/F is held for; the requester means unreleased)
-- all pop, unreleased, flt in 

Select
  '11) POP FLT H/F' note
  , Count(WO.Base_ID) countOf
   --, allocation_type, customer_id, WO.getlast_review_op_completed_close_date,rm_ready
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id like 'BOEPOP'
and wo.status in ('U')
and [EXP/FLT] = '5_FLT'


union all
 
--12  REWORK
---------
Select
'12) REWORK' note
 ,Count(Base_ID) countOf
From WORK_ORDER WO
where PART_ID like '%Rework%'
and [TYPE]= 'W'
and [Status] in ('F', 'U')
-- ** 

-- SELECT [EXP/FLT], COUNT(*) Countof from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock) GROUP BY [EXP/FLT] ORDER BY [EXP/FLT]