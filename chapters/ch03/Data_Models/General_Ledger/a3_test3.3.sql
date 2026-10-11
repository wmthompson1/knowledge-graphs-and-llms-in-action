-- a3_test3.3.sql
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
         (ACT_MATERIAL_COST) as act_material_cost,
        --  (ACT_LABOR_COST)    as act_labor_cost,
        --  (ACT_BURDEN_COST)   as act_burden_cost,
        --  (ACT_SERVICE_COST)  as act_service_cost,
         rowid
  


    from Live.dbo.WIP_ISSUE_DETAIL x
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    -- group by
    --     WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
    --     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no,rowid,ACT_MATERIAL_COST
),
observe_test as (
    select *
    from issue_agg
)
select *
from observe_test
    order by
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no,rowid,ACT_MATERIAL_COST