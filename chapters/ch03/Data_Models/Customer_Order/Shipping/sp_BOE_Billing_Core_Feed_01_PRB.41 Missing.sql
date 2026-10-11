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
--and [PackSlip] = '1505769'
and not exists(
    select 1 from LIVESupplemental.dbo.PBI_Customer_Shipments_complement feed
    where feed.PACKLIST_ID = [PackSlip]
    and feed.CUST_ORDER_ID = CUST_ORDER_ID
    and feed.COL_LINE_NO = COL_LINE_NO
    --and feed.FILTER_DATE >= '2025-01-01'
    )

-- feed 1 does not include 2025