-- ============================================================================
-- base version: 0.91 on Documentation\Schema\Data_Models\General_Ledger\a3_Version 1.0_unit_test2.30.sql
--

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
-- THIS FILE: a3_Version.93.sql
-- ============================================================================

declare @WORKORDER_BASE_ID nvarchar(50) = '1771611';  -- '1818464'; --- '1771611';

-- Optional harness override:
-- If #a3_test3_2_params exists (created by a rawXX harness file), use its value.
if object_id('tempdb..#a3_test0_91_params') is not null
begin
    select top 1
        @WORKORDER_BASE_ID = p.WORKORDER_BASE_ID
    from #a3_test0_91_params p;
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

--
-- This handles any number of dist_no values per work order and avoids
-- joining current rows to multiple previous rows.
-- ============================================================================
with
-- 0.92.01
dist_levels as (
    select

        WORKORDER_BASE_ID +
        CASE WHEN ISNULL(WORKORDER_SUB_ID,'0') = '0' THEN '' ELSE '-' + WORKORDER_SUB_ID END +
        '/' + WORKORDER_LOT_ID +
        CASE WHEN ISNULL(WORKORDER_SPLIT_ID,'0') = '0' THEN '' ELSE '.' + WORKORDER_SPLIT_ID END AS WO_NUM

        ---,DR_LAB_GL_ACCT_ID, CR_LAB_GL_ACCT_ID
        , dist_no
        ,(ACT_LABOR_COST)  as act_labor_cost,

        ROW_NUMBER() OVER (
            PARTITION BY 
              WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
              WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no
              --- ,DR_LAB_GL_ACCT_ID, CR_LAB_GL_ACCT_ID

            ORDER BY (DIST_NO)
        ) AS rn

    from Live.dbo.WIP_LABOR_DETAIL x
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)

),
-- 0.92.02
labor_ranked as (
    select
        *
    from dist_levels
)

-- sql 2
,one_row_per_dist AS (
    SELECT
        -- WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        -- WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
        WO_NUM,
        -- DR_LAB_GL_ACCT_ID, CR_LAB_GL_ACCT_ID,

        dist_no,
        sum(act_labor_cost) AS act_labor_cost
    FROM labor_ranked
    GROUP BY 
        -- WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        -- WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
        WO_NUM,
        --DR_LAB_GL_ACCT_ID, CR_LAB_GL_ACCT_ID,
        dist_no
)

select 
WO_NUM,
  -- DR_LAB_GL_ACCT_ID, CR_LAB_GL_ACCT_ID,
dist_no,act_labor_cost
from one_row_per_dist
order by 
        WO_NUM,
        -- DR_LAB_GL_ACCT_ID, CR_LAB_GL_ACCT_ID,
            dist_no
            ;