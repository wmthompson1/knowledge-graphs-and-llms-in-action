
-- step 1: get the invoice date from the input packslip

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

