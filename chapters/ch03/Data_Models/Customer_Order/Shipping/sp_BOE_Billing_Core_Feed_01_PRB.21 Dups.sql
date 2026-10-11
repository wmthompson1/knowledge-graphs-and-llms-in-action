/**********************************************************************************************
williamt 8/20

feed table LIVESupplemental.dbo.Feed_02_Core_BOE_Billing

EXEC sp_BOE_Billing_Core_Feed_01 @start= '2025-07-01', @end = '2026-08-31' 

Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
8/21/2026 improved by adding two fields to join: CUST_ORDER_ID, COL_LINE_NO


Select 
  [SPROC], [PackSlip], [unit price], [extended dollars], [expedite dollars], [special fees], [setup hours], [run hours], [expedite hours]
  , [pack slips / date], [invoice id], [comments]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
ORDER BY [PackSlip], [SPROC]

Select sum([extended dollars]) as 'total extended dollars'
  -- PackSlip, [unit price], [extended dollars], [expedite dollars], [special fees], [setup hours], [run hours], [expedite hours], [pack slips / date], [invoice id], [comments]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing

Select [Billed qty], [extended dollars], [unit price]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing

Select *
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
*********************************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET DEADLOCK_PRIORITY LOW;
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;



WITH RAW AS(
  -- step: add row_num to raw for validation
Select 
  [PackSlip], [PACK SLIPS / DATE] 
  ,CUST_ORDER_ID, COL_LINE_NO
  ,row_number() over (partition by [PackSlip] order by [PackSlip]) as row_num
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing


)
--select * from RAW;
, dups AS(
  -- step: isolate duplicates for validation
Select 
  [PackSlip]
  ,CUST_ORDER_ID, COL_LINE_NO 
  , count([PACK SLIPS / DATE] ) countof
  --,row_number() over (partition by [PackSlip] order by [PackSlip]) as row_num
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing x
WHERE EXISTS(
            SELECT 1 FROM RAW R
            WHERE R.[PackSlip] = x.[PackSlip]
            and R.CUST_ORDER_ID = x.CUST_ORDER_ID
            and R.COL_LINE_NO = x.COL_LINE_NO
            and R.row_num > 1
            )
group by packslip, CUST_ORDER_ID, COL_LINE_NO

)
-- select * from dups
, PREaGG AS(
    -- STEP: clean and prepare for aggregation
Select 
    row_number() over (partition by [PackSlip],CUST_ORDER_ID, COL_LINE_NO order by [PackSlip]) as row_num,
    SPROC, [PackSlip], CUST_ORDER_ID, COL_LINE_NO
    ,[Billed qty],[PACK SLIPS / DATE],
    ramac,
    CAST([extended dollars] AS decimal(18,2)) AS [extended dollars],
    CAST([unit price] AS decimal(18,2)) AS [unit price]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
where 1 = 1 
-- and packslip in (
--     select [PackSlip] from dups
--       )
), POST_AGG_0 AS(
  -- Step: aggregate duplicates and normalize
SELECT
     PACKSLIP, CUST_ORDER_ID, COL_LINE_NO
   , STRING_AGG(row_num, ', ') AS row_num
   , STRING_AGG(SPROC, ', ') AS SPROC
      , STRING_AGG([PACK SLIPS / DATE], ', ') AS [PACK SLIPS / DATE]
            , STRING_AGG(ramac, ', ') AS ramac
   , MAX([Billed qty]) AS [Billed qty]
   , SUM([extended dollars]) AS [extended dollars]
   , NULL AS [unit price]

FROM PREaGG
GROUP BY PACKSLIP, CUST_ORDER_ID, COL_LINE_NO
), Norm As (
  -- Step: normalize unit price
select 
    PACKSLIP
  , row_num
  , SPROC
  , ramac
  , [Billed qty]
  , [extended dollars]
  , [PACK SLIPS / DATE]
  , CAST( 
      [extended dollars] / NULLIF([Billed qty],0)
   AS decimal(18,2)) AS [unit price]
    , CUST_ORDER_ID, COL_LINE_NO
from POST_AGG_0
)
  -- Step: join normalized data with feed data for final check and validation
  -- -- 1111111111111111111111111111111111111111111111111111111111111111111111111111
  -- -- 1111111111111111111111111111111111111111111111111111111111111111111111111111
  -- -- 1111111111111111111111111111111111111111111111111111111111111111111111111111
-- Select 
--     norm.SPROC
--   , feed.BUS_STREAM
--   , feed.PACKLIST_ID
--   , norm.PACKSLIP
--   , norm.row_num

--   , norm.[Billed qty]
--   , norm.[extended dollars]
--   , norm.[unit price]
--   , norm.[PACK SLIPS / DATE]
--   ,  feed.Invoice_ID
--  -- , feed.PACKLIST_ID
--   , feed.SHIPPED_QTY, feed.SHIPPED_amount, feed.unit_price  
--  -- into #Results
-- from Norm
-- left join LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
-- on feed.PACKLIST_ID = norm.PACKSLIP
-- where norm.sproc not like '%boltboards%'

-- ORDER BY [PackSlip]
-- ;

  -- -- 2222222222222222222222222222222222222222222222222222222222222222222222222222
  -- -- 2222222222222222222222222222222222222222222222222222222222222222222222222222
  -- -- 2222222222222222222222222222222222222222222222222222222222222222222222222222
Select norm.sproc
, norm.RAMAC
, norm.packslip
, norm.CUST_ORDER_ID, norm.COL_LINE_NO
,'feed-->' note
, feed.CUST_ORDER_ID, feed.COL_LINE_NO, feed.PACKLIST_ID, feed.Invoice_ID, feed.SHIPPED_QTY, feed.SHIPPED_amount, feed.unit_price, feed.*
from LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
join norm on feed.PACKLIST_ID = norm.PACKSLIP
and norm.CUST_ORDER_ID = feed.CUST_ORDER_ID
and norm.COL_LINE_NO = feed.COL_LINE_NO

JOIN (
  Select 
      feed.CUST_ORDER_ID  
    , count(feed.PACKLIST_ID) countof
    , STRING_AGG(feed.COL_LINE_NO, ', ') AS COL_LINE_NO

  from LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
  join norm
  on feed.PACKLIST_ID = norm.PACKSLIP
  and norm.CUST_ORDER_ID = feed.CUST_ORDER_ID
  and norm.COL_LINE_NO = feed.COL_LINE_NO
  where norm.sproc not like '%boltboards%'

  group by feed.CUST_ORDER_ID, feed.COL_LINE_NO
  having count(feed.PACKLIST_ID) > 1
) X   
ON X.CUST_ORDER_ID = feed.CUST_ORDER_ID
and X.COL_LINE_NO = feed.COL_LINE_NO

where norm.sproc not like '%boltboards%'

ORDER BY feed.PACKLIST_ID,feed.[CUST_ORDER_ID]
;

-- /////////////////////////////////////////////////////////

-- -- be sure data rom process type queries is correct 
-- SELECT
--    SPROC,
--     sum(norm.[extended dollars]) AS amount_cmp_plus
--    ,sum(SHIPPED_amount) AS amount_cmp_feed
-- FROM #Results norm
-- GROUP BY SPROC

/**

-- this is the amount that must reconcile with the feed table
SELECT
   BUS_STREAM,
    sum(norm.[extended dollars]) AS amount_cmp_plus
   ,sum(SHIPPED_amount) AS amount_cmp_feed
FROM #Results norm
GROUP BY BUS_STREAM
**/

/**
SELECT feed.Invoice_ID, feed.PACKLIST_ID, feed.SHIPPED_QTY, feed.SHIPPED_amount, feed.unit_price  
 FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
WHERE FILTER_DATE >= '2025-01-01'
and PACKLIST_ID in (
    '1505517', '1505519', '1505520', '1505521',  '1505523'
)
**/

/**
-- 32,278,206
-- 21,746,825
SELECT SUM(feed.SHIPPED_amount) SHIPPED_amount 
 FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
WHERE FILTER_DATE >= '2026-01-01'
**/

-- test 8/21
-- 1501526

-- SELECT SUM(feed.SHIPPED_amount) SHIPPED_amount 
--  FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
--  where PACKLIST_ID in (
--     '1501526')
-- and FILTER_DATE >= '2026-01-01'


-- SELECT feed.SHIPPED_amount SHIPPED_amount, feed.PACKLIST_ID, feed.Invoice_ID, feed.BUS_STREAM 
--  FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
--  where PACKLIST_ID in (
--     '1501526')
-- and FILTER_DATE >= '2026-01-01'

-- test 8/21.2
-- 1499942

-- SELECT feed.SHIPPED_amount SHIPPED_amount, feed.PACKLIST_ID, feed.Invoice_ID, feed.BUS_STREAM 
--  FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
--  where PACKLIST_ID in (
--     '1499942')
-- and FILTER_DATE >= '2026-01-01';

-- -- I will need to extract rows that have duplicate packslip_id
-- WITH raw AS(
--   -- step: add row_num to raw for validation
-- SELECT feed.INVOICE_ID
--    ,count(feed.PACKLIST_ID) countof
--  FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
--  group by feed.INVOICE_ID
--  having count(feed.PACKLIST_ID) > 1
-- )
-- select PACKLIST_ID, INVOICE_ID, SHIPPED_QTY, SHIPPED_amount, unit_price 
-- ,*
-- -- feed.SHIPPED_amount SHIPPED_amount, feed.PACKLIST_ID, feed.Invoice_ID, feed.BUS_STREAM 
-- from LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
-- where feed.INVOICE_ID in (
--             select INVOICE_ID from raw
--            )
-- ORDER BY feed.PACKLIST_ID

-- -- test 8/21.3  edge case, but pointss to need of co line 
-- -- 1487434

-- SELECT feed.SHIPPED_amount SHIPPED_amount, feed.PACKLIST_ID, feed.Invoice_ID, feed.BUS_STREAM 
--  , *
--  FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
--  where PACKLIST_ID in (
--     '1487434')
-- and FILTER_DATE >= '2026-01-01';

-- -- .3 core 2
-- Select 
--   [SPROC], [PackSlip], [PART NUMBER], [unit price], [extended dollars], [expedite dollars], [special fees], [setup hours], [run hours], [expedite hours]
--   , [pack slips / date], [invoice id], [comments]
-- FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
-- where [PackSlip] in (
--     '1487434')
-- ORDER BY [PackSlip], [SPROC]

-- core  feed
-- SHIPPED_amount	PACKLIST_ID	Invoice_ID BASE_ID SPROC
-- 0	              1487434	1467643  RW1805558  FIN
-- 0	              1487434	1467643  1805558    MFG

-- min lot charge

--- .4
-- 002043751

Select 
    row_number() over (partition by [PackSlip],CUST_ORDER_ID, COL_LINE_NO order by [PackSlip]) as row_num,
    SPROC, [PackSlip], CUST_ORDER_ID, COL_LINE_NO
    ,[Billed qty],[PACK SLIPS / DATE],
    ramac,
    CAST([extended dollars] AS decimal(18,2)) AS [extended dollars],
    CAST([unit price] AS decimal(18,2)) AS [unit price]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
where 1 = 1
and [PackSlip] in (
    '1482285')

-- dup 1496800
SELECT feed.SHIPPED_amount SHIPPED_amount, feed.PACKLIST_ID, feed.Invoice_ID, feed.BUS_STREAM 
 , *
 FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
 where PACKLIST_ID in (
    SELECT PACKSLIP FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
 )
and FILTER_DATE >= '2025-01-01';

-- 1505769

Select 
    row_number() over (partition by [PackSlip],CUST_ORDER_ID, COL_LINE_NO order by [PackSlip]) as row_num,
    SPROC, [PackSlip], CUST_ORDER_ID, COL_LINE_NO
    ,[Billed qty],[PACK SLIPS / DATE],
    ramac,
    CAST([extended dollars] AS decimal(18,2)) AS [extended dollars],
    CAST([unit price] AS decimal(18,2)) AS [unit price]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
where 1 = 1
and [PackSlip] in (
    '1505769')

