-- ============================================================================
-- a3_test4.3.sql — End-item-only reconciliation (SUB_ID = '0')
-- Purpose: Test whether WORK_ORDER total maps only to SUB_ID 0 detail rows.
-- ============================================================================
declare @WORKORDER_BASE_ID nvarchar(50) = '1818464';

-- WORK_ORDER end-item total
select
    'WORK_ORDER' as source,
    isnull(ACT_MATERIAL_COST, 0) + isnull(ACT_LABOR_COST, 0)
        + isnull(ACT_BURDEN_COST, 0) + isnull(ACT_SERVICE_COST, 0) as total
from Live.dbo.WORK_ORDER
where BASE_ID = @WORKORDER_BASE_ID;

-- Detail totals for SUB_ID = '0' only, using latest dist per end-item key
select
    'WIP_ISSUE_DETAIL' as source,
    sum(i.ACT_MATERIAL_COST) as total
from Live.dbo.WIP_ISSUE_DETAIL i
where i.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
  and isnull(i.WORKORDER_SUB_ID, '') = '0'
  and i.dist_no = (
      select max(dist_no)
      from Live.dbo.WIP_ISSUE_DETAIL
      where WORKORDER_BASE_ID = i.WORKORDER_BASE_ID
        and isnull(WORKORDER_SUB_ID, '') = '0'
  );

select
    'WIP_LABOR_DETAIL' as source,
    sum(l.ACT_LABOR_COST + l.ACT_BURDEN_COST) as total
from Live.dbo.WIP_LABOR_DETAIL l
where l.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
  and isnull(l.WORKORDER_SUB_ID, '') = '0'
  and l.dist_no = (
      select max(dist_no)
      from Live.dbo.WIP_LABOR_DETAIL
      where WORKORDER_BASE_ID = l.WORKORDER_BASE_ID
        and isnull(WORKORDER_SUB_ID, '') = '0'
  );

select
    'WIP_SERVICE_DETAIL' as source,
    sum(s.ACT_SERVICE_COST) as total
from Live.dbo.WIP_SERVICE_DETAIL s
where s.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
  and isnull(s.WORKORDER_SUB_ID, '') = '0'
  and s.dist_no = (
      select max(dist_no)
      from Live.dbo.WIP_SERVICE_DETAIL
      where WORKORDER_BASE_ID = s.WORKORDER_BASE_ID
        and isnull(WORKORDER_SUB_ID, '') = '0'
  );

select
    'WIP_PAYB_DETAIL' as source,
    sum(p.ACT_MATERIAL_COST + p.ACT_LABOR_COST
        + p.ACT_BURDEN_COST + p.ACT_SERVICE_COST) as total
from Live.dbo.WIP_PAYB_DETAIL p
where p.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
  and isnull(p.WORKORDER_SUB_ID, '') = '0'
  and p.dist_no = (
      select max(dist_no)
      from Live.dbo.WIP_PAYB_DETAIL
      where WORKORDER_BASE_ID = p.WORKORDER_BASE_ID
        and isnull(WORKORDER_SUB_ID, '') = '0'
  );

-- Sub-id shape check
select
    isnull(WORKORDER_SUB_ID, '') as sub_id,
    count(*) as row_count
from Live.dbo.WIP_ISSUE_DETAIL
where WORKORDER_BASE_ID = @WORKORDER_BASE_ID
group by isnull(WORKORDER_SUB_ID, '')
order by sub_id;
