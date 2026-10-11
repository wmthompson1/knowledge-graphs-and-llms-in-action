-- ============================================================================
-- a3_test3.sql — WIP Costing Tools component diagnostic (full implementation)
-- ============================================================================
-- Purpose:
--   Decompose a WIP exception into its cost components and reconcile the
--   three Cost Analysis layers:
--     Total Transactions  -> WORK_ORDER summary cost fields
--     Total Trans Detail  -> WIP_ISSUE_DETAIL + WIP_LABOR_DETAIL +
--                            WIP_PAYB_DETAIL + WIP_SERVICE_DETAIL + SPLIT_TRANS
--     Total Posted        -> WIP_ISSUE_DIST
--
-- The query applies the delta rule: the difference between the last two
-- distributions posts to the GL. For the first distribution, the full value
-- is used (COALESCE(prev, 0)).


-- ----------------------------------------------------------------
--
-- Test harness
--     observe rows output to csv
-- 
-- ----------------------------------------------------------------

--Usage:
--    python certificate_for_receiving/border_crossing_ground_truth.py

-- Python test harness:
-- certificate_for_receiving\border_crossing_ground_truth.py
-- json ground truth path to this:
-- certificate_for_receiving\border_crossing_ground_truth.json

-- sql
-- declare @WORKORDER_BASE_ID nvarchar(50) = '1818464';
-- Inputs:
--   @WORKORDER_BASE_ID           - the work order to investigate
--   @LABOR_ACCOUNTS              - labor WIP GL accounts
--   @BURDEN_ACCOUNTS             - burden WIP GL accounts
--   @SERVICE_ACCOUNTS            - service WIP GL accounts (optional)
--
-- Output:
--   .csv  = certificate_for_receiving\border_crossing_ground_truth.csv
-- Files
-- certificate_for_receiving\border_crossing_ground_truth.csv
-- certificate_for_receiving\border_crossing_ground_truth.py
-- certificate_for_receiving\border_crossing_ground_truth.json
-- THIS FILE: a3_test3.2.sql
-- ============================================================================

declare @WORKORDER_BASE_ID nvarchar(50) = '1818464';  -- '1818464'; --- '1771611';

-- Optional harness override:
-- If #a3_test3_2_params exists (created by a rawXX harness file), use its value.
if object_id('tempdb..#a3_test3_2_params') is not null
begin
    select top 1
        @WORKORDER_BASE_ID = p.WORKORDER_BASE_ID
    from #a3_test3_2_params p;
end

-- Site-specific GL account lists. Verify against Live.dbo.ACCOUNT before use.
declare @LABOR_ACCOUNTS   table (id nvarchar(50));
declare @BURDEN_ACCOUNTS  table (id nvarchar(50));
declare @SERVICE_ACCOUNTS table (id nvarchar(50));

insert into @LABOR_ACCOUNTS   values ('163'),('6041'),('6041.1'),('6042'),('6042.1');
insert into @BURDEN_ACCOUNTS  values ('6043'),('6043.1'),('6045'),('6045.1');


-- ============================================================================
-- 2. Component deltas from detail tables (latest dist minus previous dist)
--
-- Approach:
--   1. Pre-aggregate each detail table to one row per (key + dist_no).
--   2. Use DENSE_RANK() descending by dist_no to pick the top 2 distinct
--      distributions per key.
--   3. Pivot rank 1 (current) and rank 2 (previous) into one row per key.
--   4. Compute current - COALESCE(previous, 0).
--
-- This handles any number of dist_no values per work order and avoids
-- joining current rows to multiple previous rows.
-- ============================================================================
with
issue_agg as (
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no,
        sum(ACT_MATERIAL_COST) as act_material_cost,
        sum(ACT_LABOR_COST)    as act_labor_cost,
        sum(ACT_BURDEN_COST)   as act_burden_cost,
        sum(ACT_SERVICE_COST)  as act_service_cost
    from Live.dbo.WIP_ISSUE_DETAIL
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    group by
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no
),
issue_ranked as (
    -- Rank each distribution row per key, descending by dist_no.
    -- We only need the top 2 distinct dist_no values to compute the delta.
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
        dist_no,
        act_material_cost,
        act_labor_cost,
        act_burden_cost,
        act_service_cost,
        dense_rank() over (
            partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                         WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
            order by dist_no desc
        ) as dist_rank
    from issue_agg
),
issue_top2 as (
    select *
    from issue_ranked
    where dist_rank <= 2
),
issue_pivot as (
    -- One row per key; current = rank 1, previous = rank 2.
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
        max(case when dist_rank = 1 then act_material_cost end) as cur_material_cost,
        max(case when dist_rank = 2 then act_material_cost end) as prev_material_cost,
        max(case when dist_rank = 1 then act_labor_cost    end) as cur_labor_cost,
        max(case when dist_rank = 2 then act_labor_cost    end) as prev_labor_cost,
        max(case when dist_rank = 1 then act_burden_cost   end) as cur_burden_cost,
        max(case when dist_rank = 2 then act_burden_cost   end) as prev_burden_cost,
        max(case when dist_rank = 1 then act_service_cost  end) as cur_service_cost,
        max(case when dist_rank = 2 then act_service_cost  end) as prev_service_cost
    from issue_top2
    group by
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
),
issue_delta as (
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
        cur_material_cost - coalesce(prev_material_cost, 0) as material_delta,
        cur_labor_cost    - coalesce(prev_labor_cost, 0)    as labor_delta_in_issue,
        cur_burden_cost   - coalesce(prev_burden_cost, 0)   as burden_delta_in_issue,
        cur_service_cost  - coalesce(prev_service_cost, 0)  as service_delta_in_issue
    from issue_pivot
),

labor_agg as (
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no,
        sum(ACT_LABOR_COST)  as act_labor_cost,
        sum(ACT_BURDEN_COST) as act_burden_cost
    from Live.dbo.WIP_LABOR_DETAIL
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    group by
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no
),
labor_ranked as (
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
        dist_no,
        act_labor_cost,
        act_burden_cost,
        dense_rank() over (
            partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                         WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
            order by dist_no desc
        ) as dist_rank
    from labor_agg
),
labor_top2 as (
    select *
    from labor_ranked
    where dist_rank <= 2
),
labor_pivot as (
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
        max(case when dist_rank = 1 then act_labor_cost  end) as cur_labor_cost,
        max(case when dist_rank = 2 then act_labor_cost  end) as prev_labor_cost,
        max(case when dist_rank = 1 then act_burden_cost end) as cur_burden_cost,
        max(case when dist_rank = 2 then act_burden_cost end) as prev_burden_cost
    from labor_top2
    group by
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
),
labor_delta as (
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
        cur_labor_cost  - coalesce(prev_labor_cost, 0)  as labor_delta,
        cur_burden_cost - coalesce(prev_burden_cost, 0) as burden_delta
    from labor_pivot
),

service_agg as (
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no,
        sum(ACT_SERVICE_COST) as act_service_cost
    from Live.dbo.WIP_SERVICE_DETAIL
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    group by
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no
),
service_ranked as (
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
        dist_no,
        act_service_cost,
        dense_rank() over (
            partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                         WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
            order by dist_no desc
        ) as dist_rank
    from service_agg
),
service_top2 as (
    select *
    from service_ranked
    where dist_rank <= 2
),
service_pivot as (
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
        max(case when dist_rank = 1 then act_service_cost end) as cur_service_cost,
        max(case when dist_rank = 2 then act_service_cost end) as prev_service_cost
    from service_top2
    group by
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
),
service_delta as (
    select
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
        cur_service_cost - coalesce(prev_service_cost, 0) as service_delta
    from service_pivot
)
select
    coalesce(i.WORKORDER_TYPE, l.WORKORDER_TYPE, s.WORKORDER_TYPE)   as WORKORDER_TYPE,
    coalesce(i.WORKORDER_BASE_ID, l.WORKORDER_BASE_ID, s.WORKORDER_BASE_ID) as WORKORDER_BASE_ID,
    coalesce(i.WORKORDER_LOT_ID, l.WORKORDER_LOT_ID, s.WORKORDER_LOT_ID)     as WORKORDER_LOT_ID,
    coalesce(i.WORKORDER_SPLIT_ID, l.WORKORDER_SPLIT_ID, s.WORKORDER_SPLIT_ID) as WORKORDER_SPLIT_ID,
    coalesce(i.WORKORDER_SUB_ID, l.WORKORDER_SUB_ID, s.WORKORDER_SUB_ID)     as WORKORDER_SUB_ID,
    isnull(i.material_delta, 0)                                      as material_delta,
    isnull(l.labor_delta, 0)                                         as labor_delta,
    isnull(l.burden_delta, 0)                                        as burden_delta,
    isnull(s.service_delta, 0)                                       as service_delta,
    isnull(i.labor_delta_in_issue, 0)                                as labor_delta_in_issue_detail,
    isnull(i.burden_delta_in_issue, 0)                               as burden_delta_in_issue_detail
from issue_delta i
full outer join labor_delta l
    on l.WORKORDER_TYPE = i.WORKORDER_TYPE and l.WORKORDER_BASE_ID = i.WORKORDER_BASE_ID
    and l.WORKORDER_LOT_ID = i.WORKORDER_LOT_ID and l.WORKORDER_SPLIT_ID = i.WORKORDER_SPLIT_ID
    and l.WORKORDER_SUB_ID = i.WORKORDER_SUB_ID
full outer join service_delta s
    on s.WORKORDER_TYPE = coalesce(l.WORKORDER_TYPE, i.WORKORDER_TYPE)
    and s.WORKORDER_BASE_ID = coalesce(l.WORKORDER_BASE_ID, i.WORKORDER_BASE_ID)
    and s.WORKORDER_LOT_ID = coalesce(l.WORKORDER_LOT_ID, i.WORKORDER_LOT_ID)
    and s.WORKORDER_SPLIT_ID = coalesce(l.WORKORDER_SPLIT_ID, i.WORKORDER_SPLIT_ID)
    and s.WORKORDER_SUB_ID = coalesce(l.WORKORDER_SUB_ID, i.WORKORDER_SUB_ID);