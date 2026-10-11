-- ============================================================================
-- a3_test4.2.sql — Component drilldown for single WO
-- Purpose: Show material/labor/burden/service/payable per detail source vs
--          WORK_ORDER component fields to isolate where the 1,426.02 gap lives.
-- ============================================================================
declare @WORKORDER_BASE_ID nvarchar(50) = '1818464';

-- WORK_ORDER component totals
select
    'WORK_ORDER' as source,
    isnull(ACT_MATERIAL_COST, 0) as material,
    isnull(ACT_LABOR_COST, 0)    as labor,
    isnull(ACT_BURDEN_COST, 0)   as burden,
    isnull(ACT_SERVICE_COST, 0)  as service,
    0                            as payable,
    isnull(ACT_MATERIAL_COST, 0) + isnull(ACT_LABOR_COST, 0)
        + isnull(ACT_BURDEN_COST, 0) + isnull(ACT_SERVICE_COST, 0) as total
from Live.dbo.WORK_ORDER
where BASE_ID = @WORKORDER_BASE_ID;

-- WIP_ISSUE_DETAIL — latest dist material
select
    'WIP_ISSUE_DETAIL' as source,
    sum(i.ACT_MATERIAL_COST) as material,
    0                        as labor,
    0                        as burden,
    0                        as service,
    0                        as payable,
    sum(i.ACT_MATERIAL_COST) as total
from (
    select top 1 with ties *
    from Live.dbo.WIP_ISSUE_DETAIL
    where WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    order by row_number() over (
        partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
        order by dist_no desc
    )
) i;

-- WIP_LABOR_DETAIL — latest dist labor + burden
select
    'WIP_LABOR_DETAIL' as source,
    0                                       as material,
    sum(l.ACT_LABOR_COST)                   as labor,
    sum(l.ACT_BURDEN_COST)                  as burden,
    0                                       as service,
    0                                       as payable,
    sum(l.ACT_LABOR_COST + l.ACT_BURDEN_COST) as total
from (
    select top 1 with ties *
    from Live.dbo.WIP_LABOR_DETAIL
    where WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    order by row_number() over (
        partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
        order by dist_no desc
    )
) l;

-- WIP_SERVICE_DETAIL — latest dist service
select
    'WIP_SERVICE_DETAIL' as source,
    0                        as material,
    0                        as labor,
    0                        as burden,
    sum(s.ACT_SERVICE_COST)  as service,
    0                        as payable,
    sum(s.ACT_SERVICE_COST)  as total
from (
    select top 1 with ties *
    from Live.dbo.WIP_SERVICE_DETAIL
    where WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    order by row_number() over (
        partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
        order by dist_no desc
    )
) s;

-- WIP_PAYB_DETAIL — latest dist payable (all four cost fields)
select
    'WIP_PAYB_DETAIL' as source,
    sum(p.ACT_MATERIAL_COST) as material,
    sum(p.ACT_LABOR_COST)    as labor,
    sum(p.ACT_BURDEN_COST)   as burden,
    sum(p.ACT_SERVICE_COST)  as service,
    sum(p.ACT_MATERIAL_COST + p.ACT_LABOR_COST
        + p.ACT_BURDEN_COST + p.ACT_SERVICE_COST) as payable,
    sum(p.ACT_MATERIAL_COST + p.ACT_LABOR_COST
        + p.ACT_BURDEN_COST + p.ACT_SERVICE_COST) as total
from (
    select top 1 with ties *
    from Live.dbo.WIP_PAYB_DETAIL
    where WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    order by row_number() over (
        partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
        order by dist_no desc
    )
) p;

-- Key-shape diagnostic: how many dist_no per detail table
select 'WIP_ISSUE_DETAIL' as table_name,
       count(distinct dist_no) as distinct_dist_count,
       min(dist_no) as min_dist, max(dist_no) as max_dist
from Live.dbo.WIP_ISSUE_DETAIL where WORKORDER_BASE_ID = @WORKORDER_BASE_ID
union all
select 'WIP_LABOR_DETAIL',
       count(distinct dist_no), min(dist_no), max(dist_no)
from Live.dbo.WIP_LABOR_DETAIL where WORKORDER_BASE_ID = @WORKORDER_BASE_ID
union all
select 'WIP_SERVICE_DETAIL',
       count(distinct dist_no), min(dist_no), max(dist_no)
from Live.dbo.WIP_SERVICE_DETAIL where WORKORDER_BASE_ID = @WORKORDER_BASE_ID
union all
select 'WIP_PAYB_DETAIL',
       count(distinct dist_no), min(dist_no), max(dist_no)
from Live.dbo.WIP_PAYB_DETAIL where WORKORDER_BASE_ID = @WORKORDER_BASE_ID;
