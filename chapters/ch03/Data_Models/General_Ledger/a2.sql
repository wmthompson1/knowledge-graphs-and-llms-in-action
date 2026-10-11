

--select * from dbo.work_order
--where posting_candidate = 'Y';

-- WIP_LABOR_DETAIL

declare @WORKORDER_BASE_ID nvarchar(50) = null;  --'1822226';

select top 10000 
   d.WORKORDER_BASE_ID
   ,a.id, a.DESCRIPTION, d.GL_ACCOUNT_ID, d.AMOUNT_TYPE, d.AMOUNT
  -- ,*
from WIP_ISSUE_DIST d (nolock)
join account a (nolock)
on a.id = d.GL_ACCOUNT_ID
where WORKORDER_BASE_ID >= '1800000'
and (WORKORDER_BASE_ID  = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
and POSTING_DATE = '06/30/2026'
--and id in ('6041','6042','6043','6045')
and id in ('163')
--group by    a.id, a.DESCRIPTION
--order by a.id 
-- union all
-- select top 10000 
--    d.WORKORDER_BASE_ID
--    ,a.id, a.DESCRIPTION, d.GL_ACCOUNT_ID, d.AMOUNT_TYPE, d.AMOUNT
--    --,*
-- from WIP_ISSUE_DIST d (nolock)
-- join account a (nolock)
-- on a.id = d.GL_ACCOUNT_ID
-- where WORKORDER_BASE_ID >= '1800000'
-- and (WORKORDER_BASE_ID  = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
-- and POSTING_DATE = '06/30/2026'
-- and id not in ('6041','6042','6043','6045')
-- --group by    a.id, a.DESCRIPTION
-- --order by a.id 
union all
select top 10000 
     d.WORKORDER_BASE_ID
   , CAST(d.DR_LAB_GL_ACCT_ID AS NVARCHAR(50)) AS dist_no
   , 'Total Posted' AS [DESCRIPTION]
   , DR_LAB_GL_ACCT_ID AS [GL_ACCOUNT_ID]
   , 'DR' AS AMOUNT_TYPE
   -- Aggregate labor and burden costs by work order and distribution number
   , sum(ACT_LABOR_COST + ACT_BURDEN_COST) AS AMOUNT
from WIP_LABOR_DETAIL d (nolock)
where WORKORDER_BASE_ID >= '1800000'
and (WORKORDER_BASE_ID  = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
--and POSTING_DATE = '06/30/2026'
--and DR_LAB_GL_ACCT_ID in ('163')
AND N'163' IN (DR_LAB_GL_ACCT_ID,DR_BUR_GL_ACCT_ID)
--group by    a.id, a.DESCRIPTION
--order by d.WORKORDER_BASE_ID, d.dist_no
GROUP BY
    d.WORKORDER_BASE_ID,
    d.dist_no,
    DR_LAB_GL_ACCT_ID
    -- ACT_LABOR_COST,
    -- ACT_BURDEN_COST
order by d.WORKORDER_BASE_ID
-- willimt 7/24
