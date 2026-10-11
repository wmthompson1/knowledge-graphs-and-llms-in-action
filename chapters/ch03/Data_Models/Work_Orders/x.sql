-- select
--     -- would you list work_order keys here for easier joins or just use BASE_ID, LOT_ID, SPLIT_ID?
--     a.base_id, a.lot_id, a.split_id, a.sub_id, a.type
--     , a.PART_ID, a.WONUM, a.DESIRED_QTY, a.STATUS
--     , a.CUSTOMER_ORDER, a.LINE_NO, a.CUSTOMER_ID, a.allocation_type
--     , a.CurrentOperation, a.StatusCurrOp, a.PRINTED_DATE
-- 	, a.RM_READY  --  NO if rm not avail
-- 	, a.getlast_review_op_completed_close_date -- date of review op (is start for planning)
-- from LIVESupplemental.dbo.WODS_Output_ETL a (nolock)
-- sp_whoisactive

-- select top 1 * from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
-- where 1=1
/**
LEGEND
   FLT (First Lot Testing) or First Article Testing (FAT) 
   EXP - Expedite
   H/F = Held for
   P/D - PAST DUE


**/

--## 2  CMP P/D
-- WO with customer order info to determine if late due to customer or internal
-- start_date = getlast_review_op_completed_close_date
-- today is june 11, so anything start date +3 is late (3 business days), 
-- like June 6
-- work order count
-- add the sec for pd 
-- late_date <= start_date + 3;  -- if today <= late_date then late else on time

Select
  'Metric 2' note
--   , start_date = getlast_review_op_completed_close_date
--   , late_date = dateadd(day,3,getlast_review_op_completed_close_date)
--   , today = getdate()
--   , iif(dateadd(day,3,getlast_review_op_completed_close_date) <= getdate()
--        , 'Late', 'On Time') as status
--   , iif(dateadd(day,3,getlast_review_op_completed_close_date) <= getdate()
--        , 1, 0) as status
  , Count(WO.Base_ID)
---from Work_Order WO
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
Left Outer Join Demand_Supply_Link DSL
on DSL.SUPPLY_BASE_ID = WO.BASE_ID
and DSL.SUPPLY_LOT_ID = WO.LOT_ID
and DSL.SUPPLY_SPLIT_ID = WO.SPLIT_ID
and DSL.SUPPLY_SUB_ID = WO.SUB_ID
Left Outer Join CUST_ORDER_LINE COL
on COL.Cust_Order_ID = DSL.Demand_Base_ID
and COL.Line_No = DSL.Demand_Seq_No
Left Outer Join CUSTOMER_ORDER CO
on CO.ID = COL.Cust_Order_ID
 Where CO.Customer_ID = 'BOE609'
and WO.[TYPE] = 'W'
and WO.[STATUS] = 'F'
and getlast_review_op_completed_close_date <= dateadd(day,3,getdate())