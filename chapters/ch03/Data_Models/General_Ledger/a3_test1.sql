-- re detail tables show history
-- ** The difference between the last two distributions will be what posts to the general ledger.**
-- Q: what if there is a new dist (that hadn't been in prior) and can we assume that is the initial value?
declare @WORKORDER_BASE_ID nvarchar(50) = '1771611';  -- '1772726'

-- declare @WORKORDER_BASE_ID nvarchar(50) = '1800269';  --'1822226';

-- grain of delta should include distribution number and GL account.id
select 
  'A' AS source,
   d.WORKORDER_BASE_ID
   ,a.id, a.DESCRIPTION, d.GL_ACCOUNT_ID, d.AMOUNT_TYPE, d.AMOUNT
  -- ,*
from WIP_ISSUE_DIST d (nolock)
join account a (nolock)
on a.id = d.GL_ACCOUNT_ID
where WORKORDER_BASE_ID >= '1600000' 
and (WORKORDER_BASE_ID  = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
-- and POSTING_DATE = '06/30/2026'
and id in ('163','6041','6041.1','6042','6042.1','6043','6043.1','6045','6045.1')
group by    a.id, a.DESCRIPTION, d.WORKORDER_BASE_ID, d.GL_ACCOUNT_ID, d.AMOUNT_TYPE, d.AMOUNT
---order by a.id 
union all
-- apologies - the block of code from line 25 to line 38 may bne redundant as I am, calculatinmg wip costs separately.
select 
  'B' AS source,
   d.WORKORDER_BASE_ID
   ,a.id, a.DESCRIPTION, d.GL_ACCOUNT_ID, d.AMOUNT_TYPE, d.AMOUNT
   --,*
from WIP_ISSUE_DIST d (nolock)
join account a (nolock)
on a.id = d.GL_ACCOUNT_ID
where WORKORDER_BASE_ID >= '1600000'
and (WORKORDER_BASE_ID  = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
and POSTING_DATE = '06/30/2026'
and id not in ('163','6041','6041.1','6042','6042.1','6043','6043.1','6045','6045.1')
group by    a.id, a.DESCRIPTION, d.WORKORDER_BASE_ID, d.GL_ACCOUNT_ID, d.AMOUNT_TYPE, d.AMOUNT
order by a.id 
;
-- union all
-- select   
--   'B' AS source,
--      d.WORKORDER_BASE_ID
--  --  , CAST(d.DR_LAB_GL_ACCT_ID AS NVARCHAR(50)) AS dist_no
--    , null as x
--    , 'Total Posted' AS [DESCRIPTION]
--    , DR_LAB_GL_ACCT_ID AS [GL_ACCOUNT_ID]
--    , 'DR' AS AMOUNT_TYPE
--    -- Aggregate labor and burden costs by work order and distribution number
--    , sum(ACT_LABOR_COST + ACT_BURDEN_COST) AS AMOUNT
-- from WIP_LABOR_DETAIL d (nolock)
-- where WORKORDER_BASE_ID >= '1800000' and WORKORDER_BASE_ID <= '1802702'
-- and (WORKORDER_BASE_ID  = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
-- and d.WORKORDER_BASE_ID in(
--             select 
--             d.WORKORDER_BASE_ID
--             from WIP_ISSUE_DIST d (nolock)
--             join account a (nolock)
--             on a.id = d.GL_ACCOUNT_ID
--             --where WORKORDER_BASE_ID >= '1800000' and WORKORDER_BASE_ID <= '1802702'
--             and POSTING_DATE = '06/30/2026'
-- )


-- AND N'163' IN (DR_LAB_GL_ACCT_ID,DR_BUR_GL_ACCT_ID)
-- --group by    a.id, a.DESCRIPTION
-- --order by d.WORKORDER_BASE_ID, d.dist_no
-- GROUP BY
--     d.WORKORDER_BASE_ID,
--  --   d.dist_no,
--     DR_LAB_GL_ACCT_ID
--     -- ACT_LABOR_COST,
--     -- ACT_BURDEN_COST
-- order by d.WORKORDER_BASE_ID
-- -- willimt 7/24
-- ;

-- the difference between the last two distributions will be what posts to the general ledger
-- see the detailed history in the WIP_LABOR_DETAIL tables
-- grain of delta should include distribution number and GL account.id
with DELTA AS(
    SELECT *
    FROM (
        SELECT
            d2.WORKORDER_BASE_ID,
            d2.dist_no AS max_dist_no,
            LAG(d2.dist_no) OVER (PARTITION BY d2.WORKORDER_BASE_ID ORDER BY d2.dist_no) AS prev_dist_no,
            RANK() OVER (PARTITION BY d2.WORKORDER_BASE_ID ORDER BY d2.dist_no DESC) AS rnk
        FROM (
            SELECT DISTINCT WORKORDER_BASE_ID, dist_no
            FROM WIP_LABOR_DETAIL
            WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID 
        ) d2
    ) ranked
    WHERE rnk = 1
), dAt as (
    SELECT 
        d.*,
        sub.max_dist_no,
        sub.prev_dist_no
    FROM WIP_LABOR_DETAIL d
    JOIN DELTA sub
    ON d.WORKORDER_BASE_ID = sub.WORKORDER_BASE_ID
    AND d.dist_no = sub.max_dist_no
)
-- now subtract the values of each  labor and burden cost for the last distribution from the previous one.
-- If there is no previous distribution (first/initial dist for this work order key),
-- COALESCE treats the missing previous value as 0 so the diff equals the full
-- initial distribution amount. This matches the KB rule: the difference between
-- the last two distributions posts to the GL; when only one distribution exists,
-- that single distribution value is the amount that posts.
, diff_1 as (
    SELECT 
        d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID, d.WORKORDER_SUB_ID, d.WORKORDER_SPLIT_ID, d.WORKORDER_TYPE,
        d.dist_no AS max_dist_no,
        d.prev_dist_no,
        d.ACT_LABOR_COST - COALESCE(prev.ACT_LABOR_COST, 0) AS labor_cost_diff,
        d.ACT_BURDEN_COST - COALESCE(prev.ACT_BURDEN_COST, 0) AS burden_cost_diff,
        CASE WHEN prev.dist_no IS NULL THEN 1 ELSE 0 END AS is_initial_dist
    FROM dAt d
    LEFT JOIN dAt prev
    ON d.WORKORDER_BASE_ID = prev.WORKORDER_BASE_ID
    AND d.WORKORDER_LOT_ID = prev.WORKORDER_LOT_ID
    AND d.WORKORDER_SUB_ID = prev.WORKORDER_SUB_ID
    AND d.WORKORDER_SPLIT_ID = prev.WORKORDER_SPLIT_ID
    AND d.WORKORDER_TYPE = prev.WORKORDER_TYPE
    AND d.prev_dist_no = prev.dist_no
)
select 
   d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID, d.WORKORDER_SUB_ID, d.WORKORDER_SPLIT_ID, d.WORKORDER_TYPE,
        d.max_dist_no,
        d.prev_dist_no,
   sum(labor_cost_diff) AS total_labor_cost_diff,
   sum(burden_cost_diff) AS total_burden_cost_diff

from diff_1 d
group by d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID, d.WORKORDER_SUB_ID, d.WORKORDER_SPLIT_ID
, d.WORKORDER_TYPE, d.max_dist_no, d.prev_dist_no
;

-- Compare the calculated labor+burden delta to the actual ledger postings in WIP_ISSUE_DIST.
-- The ledger stores signed amounts via AMOUNT_TYPE ('DR' positive, 'CR' negative in this view).
-- A variance of zero means the KB rule "difference between the last two distributions"
-- matches the GL distribution for this work order.
WITH DELTA AS(
    SELECT *
    FROM (
        SELECT
            d2.WORKORDER_BASE_ID,
            d2.WORKORDER_LOT_ID,
            d2.WORKORDER_SPLIT_ID,
            d2.WORKORDER_SUB_ID,
            d2.WORKORDER_TYPE,
            d2.dist_no AS max_dist_no,
            LAG(d2.dist_no) OVER (PARTITION BY d2.WORKORDER_BASE_ID, d2.WORKORDER_LOT_ID, d2.WORKORDER_SPLIT_ID, d2.WORKORDER_SUB_ID, d2.WORKORDER_TYPE ORDER BY d2.dist_no) AS prev_dist_no,
            RANK() OVER (PARTITION BY d2.WORKORDER_BASE_ID, d2.WORKORDER_LOT_ID, d2.WORKORDER_SPLIT_ID, d2.WORKORDER_SUB_ID, d2.WORKORDER_TYPE ORDER BY d2.dist_no DESC) AS rnk
        FROM (
            SELECT DISTINCT WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, WORKORDER_TYPE, dist_no
            FROM WIP_LABOR_DETAIL
            WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID 
        ) d2
    ) ranked
    WHERE rnk = 1
), dAt as (
    SELECT 
        d.*,
        sub.max_dist_no,
        sub.prev_dist_no
    FROM WIP_LABOR_DETAIL d
    JOIN DELTA sub
    ON d.WORKORDER_BASE_ID = sub.WORKORDER_BASE_ID
    AND d.WORKORDER_LOT_ID = sub.WORKORDER_LOT_ID
    AND d.WORKORDER_SPLIT_ID = sub.WORKORDER_SPLIT_ID
    AND d.WORKORDER_SUB_ID = sub.WORKORDER_SUB_ID
    AND d.WORKORDER_TYPE = sub.WORKORDER_TYPE
    AND d.dist_no = sub.max_dist_no
), diff_1 as (
    SELECT 
        d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID, d.WORKORDER_SUB_ID, d.WORKORDER_SPLIT_ID, d.WORKORDER_TYPE,
        d.dist_no AS max_dist_no,
        d.prev_dist_no,
        d.ACT_LABOR_COST - COALESCE(prev.ACT_LABOR_COST, 0) AS labor_cost_diff,
        d.ACT_BURDEN_COST - COALESCE(prev.ACT_BURDEN_COST, 0) AS burden_cost_diff
    FROM dAt d
    LEFT JOIN dAt prev
    ON d.WORKORDER_BASE_ID = prev.WORKORDER_BASE_ID
    AND d.WORKORDER_LOT_ID = prev.WORKORDER_LOT_ID
    AND d.WORKORDER_SUB_ID = prev.WORKORDER_SUB_ID
    AND d.WORKORDER_SPLIT_ID = prev.WORKORDER_SPLIT_ID
    AND d.WORKORDER_TYPE = prev.WORKORDER_TYPE
    AND d.prev_dist_no = prev.dist_no
), calc_delta as (
    SELECT
        WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SUB_ID, WORKORDER_SPLIT_ID, WORKORDER_TYPE,
        max_dist_no,
        SUM(labor_cost_diff + burden_cost_diff) AS calculated_delta
    FROM diff_1
    GROUP BY WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SUB_ID, WORKORDER_SPLIT_ID, WORKORDER_TYPE, max_dist_no
), ledger as (
    SELECT
        d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID, d.WORKORDER_SUB_ID, d.WORKORDER_SPLIT_ID, d.WORKORDER_TYPE,
        SUM(CASE WHEN d.AMOUNT_TYPE = 'DR' THEN d.AMOUNT ELSE -d.AMOUNT END) AS ledger_amount
    FROM WIP_ISSUE_DIST d
    JOIN account a ON a.id = d.GL_ACCOUNT_ID
    WHERE d.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
      AND a.id IN ('163','6041','6041.1','6042','6042.1','6043','6043.1','6045','6045.1')
    GROUP BY d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID, d.WORKORDER_SUB_ID, d.WORKORDER_SPLIT_ID, d.WORKORDER_TYPE
)
SELECT
    c.WORKORDER_BASE_ID, c.WORKORDER_LOT_ID, c.WORKORDER_SUB_ID, c.WORKORDER_SPLIT_ID, c.WORKORDER_TYPE,
    c.max_dist_no,
    c.calculated_delta,
    l.ledger_amount,
    c.calculated_delta - l.ledger_amount AS variance,
    CASE WHEN ABS(c.calculated_delta - l.ledger_amount) < 0.01 THEN 'MATCH' ELSE 'MISMATCH' END AS status
FROM calc_delta c
LEFT JOIN ledger l
    ON c.WORKORDER_BASE_ID = l.WORKORDER_BASE_ID
    AND c.WORKORDER_LOT_ID = l.WORKORDER_LOT_ID
    AND c.WORKORDER_SUB_ID = l.WORKORDER_SUB_ID
    AND c.WORKORDER_SPLIT_ID = l.WORKORDER_SPLIT_ID
    AND c.WORKORDER_TYPE = l.WORKORDER_TYPE
ORDER BY c.WORKORDER_BASE_ID, c.WORKORDER_LOT_ID, c.WORKORDER_SUB_ID, c.WORKORDER_SPLIT_ID;

-- Reproduce the labor+burden portion of the Cost Analysis WIP total.
-- Original intent is to validate labor and burden only; material is netted out of WIP.
-- Labor/burden WIP accounts are defined by the account list used in the first query:
-- ('163','6041','6041.1','6042','6042.1','6043','6043.1','6045','6045.1').
WITH latest_labor_dist AS (
    SELECT TOP 1 WITH TIES
        WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, WORKORDER_TYPE, dist_no
    FROM WIP_LABOR_DETAIL
    WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    ORDER BY ROW_NUMBER() OVER (
        PARTITION BY WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, WORKORDER_TYPE
        ORDER BY dist_no DESC
    )
), latest_issue_dist AS (
    SELECT TOP 1 WITH TIES
        WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, WORKORDER_TYPE, dist_no
    FROM WIP_ISSUE_DETAIL
    WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    ORDER BY ROW_NUMBER() OVER (
        PARTITION BY WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, WORKORDER_TYPE
        ORDER BY dist_no DESC
    )
), labor_total AS (
    SELECT
        ld.WORKORDER_BASE_ID, ld.WORKORDER_LOT_ID, ld.WORKORDER_SPLIT_ID, ld.WORKORDER_SUB_ID, ld.WORKORDER_TYPE,
        SUM(d.ACT_LABOR_COST + d.ACT_BURDEN_COST) AS labor_burden_total
    FROM latest_labor_dist ld
    JOIN WIP_LABOR_DETAIL d
        ON d.WORKORDER_BASE_ID = ld.WORKORDER_BASE_ID
        AND d.WORKORDER_LOT_ID = ld.WORKORDER_LOT_ID
        AND d.WORKORDER_SPLIT_ID = ld.WORKORDER_SPLIT_ID
        AND d.WORKORDER_SUB_ID = ld.WORKORDER_SUB_ID
        AND d.WORKORDER_TYPE = ld.WORKORDER_TYPE
        AND d.dist_no = ld.dist_no
    GROUP BY ld.WORKORDER_BASE_ID, ld.WORKORDER_LOT_ID, ld.WORKORDER_SPLIT_ID, ld.WORKORDER_SUB_ID, ld.WORKORDER_TYPE
), issue_total AS (
    SELECT
        lid.WORKORDER_BASE_ID, lid.WORKORDER_LOT_ID, lid.WORKORDER_SPLIT_ID, lid.WORKORDER_SUB_ID, lid.WORKORDER_TYPE,
        SUM(d.ACT_MATERIAL_COST + d.ACT_LABOR_COST + d.ACT_BURDEN_COST + d.ACT_SERVICE_COST) AS issue_total
    FROM latest_issue_dist lid
    JOIN WIP_ISSUE_DETAIL d
        ON d.WORKORDER_BASE_ID = lid.WORKORDER_BASE_ID
        AND d.WORKORDER_LOT_ID = lid.WORKORDER_LOT_ID
        AND d.WORKORDER_SPLIT_ID = lid.WORKORDER_SPLIT_ID
        AND d.WORKORDER_SUB_ID = lid.WORKORDER_SUB_ID
        AND d.WORKORDER_TYPE = lid.WORKORDER_TYPE
        AND d.dist_no = lid.dist_no
    GROUP BY lid.WORKORDER_BASE_ID, lid.WORKORDER_LOT_ID, lid.WORKORDER_SPLIT_ID, lid.WORKORDER_SUB_ID, lid.WORKORDER_TYPE
)
SELECT
    COALESCE(lt.WORKORDER_BASE_ID, it.WORKORDER_BASE_ID) AS WORKORDER_BASE_ID,
    COALESCE(lt.WORKORDER_LOT_ID, it.WORKORDER_LOT_ID) AS WORKORDER_LOT_ID,
    COALESCE(lt.WORKORDER_SPLIT_ID, it.WORKORDER_SPLIT_ID) AS WORKORDER_SPLIT_ID,
    COALESCE(lt.WORKORDER_SUB_ID, it.WORKORDER_SUB_ID) AS WORKORDER_SUB_ID,
    COALESCE(lt.WORKORDER_TYPE, it.WORKORDER_TYPE) AS WORKORDER_TYPE,
    ISNULL(lt.labor_burden_total, 0) AS labor_burden_total,
    ISNULL(it.issue_total, 0) AS material_labor_burden_service_total,
    ISNULL(lt.labor_burden_total, 0) + ISNULL(it.issue_total, 0) AS total_wip,
    9263.71 AS screenshot_total_transactions,
    9263.71 - ISNULL(it.issue_total, 0) AS implied_labor_burden_in_screenshot
FROM labor_total lt
FULL OUTER JOIN issue_total it
    ON lt.WORKORDER_BASE_ID = it.WORKORDER_BASE_ID
    AND lt.WORKORDER_LOT_ID = it.WORKORDER_LOT_ID
    AND lt.WORKORDER_SPLIT_ID = it.WORKORDER_SPLIT_ID
    AND lt.WORKORDER_SUB_ID = it.WORKORDER_SUB_ID
    AND lt.WORKORDER_TYPE = it.WORKORDER_TYPE;

-- Test whether WIP_ISSUE_DETAIL is properly constructed by comparing it to WIP_ISSUE_DIST.
-- Restricted to labor/burden WIP accounts only, matching the original validation intent.
WITH latest_issue AS (
    SELECT TOP 1 WITH TIES
        WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, WORKORDER_TYPE, dist_no
    FROM WIP_ISSUE_DETAIL
    WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    ORDER BY ROW_NUMBER() OVER (
        PARTITION BY WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, WORKORDER_TYPE
        ORDER BY dist_no DESC
    )
), detail_components AS (
    SELECT
        li.WORKORDER_BASE_ID, li.WORKORDER_LOT_ID, li.WORKORDER_SPLIT_ID, li.WORKORDER_SUB_ID, li.WORKORDER_TYPE,
        li.dist_no,
        SUM(d.ACT_MATERIAL_COST) AS detail_material,
        SUM(d.ACT_LABOR_COST) AS detail_labor,
        SUM(d.ACT_BURDEN_COST) AS detail_burden,
        SUM(d.ACT_SERVICE_COST) AS detail_service
    FROM latest_issue li
    JOIN WIP_ISSUE_DETAIL d
        ON d.WORKORDER_BASE_ID = li.WORKORDER_BASE_ID
        AND d.WORKORDER_LOT_ID = li.WORKORDER_LOT_ID
        AND d.WORKORDER_SPLIT_ID = li.WORKORDER_SPLIT_ID
        AND d.WORKORDER_SUB_ID = li.WORKORDER_SUB_ID
        AND d.WORKORDER_TYPE = li.WORKORDER_TYPE
        AND d.dist_no = li.dist_no
    GROUP BY li.WORKORDER_BASE_ID, li.WORKORDER_LOT_ID, li.WORKORDER_SPLIT_ID, li.WORKORDER_SUB_ID, li.WORKORDER_TYPE, li.dist_no
), ledger_by_account AS (
    SELECT
        d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID, d.WORKORDER_SPLIT_ID, d.WORKORDER_SUB_ID, d.WORKORDER_TYPE,
        d.dist_no,
        a.id AS gl_account_id,
        a.DESCRIPTION,
        SUM(CASE WHEN d.AMOUNT_TYPE = 'DR' THEN d.AMOUNT ELSE -d.AMOUNT END) AS ledger_net_amount
    FROM WIP_ISSUE_DIST d
    JOIN account a ON a.id = d.GL_ACCOUNT_ID
    WHERE d.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
      AND a.id IN ('163','6041','6041.1','6042','6042.1','6043','6043.1','6045','6045.1')
    GROUP BY d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID, d.WORKORDER_SPLIT_ID, d.WORKORDER_SUB_ID, d.WORKORDER_TYPE, d.dist_no, a.id, a.DESCRIPTION
)
SELECT
    dc.WORKORDER_BASE_ID, dc.WORKORDER_LOT_ID, dc.WORKORDER_SPLIT_ID, dc.WORKORDER_SUB_ID, dc.WORKORDER_TYPE,
    dc.dist_no,
    dc.detail_material,
    dc.detail_labor,
    dc.detail_burden,
    dc.detail_service,
    dc.detail_material + dc.detail_labor + dc.detail_burden + dc.detail_service AS detail_total,
    SUM(ISNULL(lb.ledger_net_amount, 0)) AS ledger_total_all_accounts,
    STRING_AGG(lb.gl_account_id + ' (' + lb.DESCRIPTION + '): ' + CAST(lb.ledger_net_amount AS NVARCHAR(50)), '; ') AS ledger_accounts
FROM detail_components dc
LEFT JOIN ledger_by_account lb
    ON dc.WORKORDER_BASE_ID = lb.WORKORDER_BASE_ID
    AND dc.WORKORDER_LOT_ID = lb.WORKORDER_LOT_ID
    AND dc.WORKORDER_SPLIT_ID = lb.WORKORDER_SPLIT_ID
    AND dc.WORKORDER_SUB_ID = lb.WORKORDER_SUB_ID
    AND dc.WORKORDER_TYPE = lb.WORKORDER_TYPE
    AND dc.dist_no = lb.dist_no
GROUP BY dc.WORKORDER_BASE_ID, dc.WORKORDER_LOT_ID, dc.WORKORDER_SPLIT_ID, dc.WORKORDER_SUB_ID, dc.WORKORDER_TYPE, dc.dist_no,
         dc.detail_material, dc.detail_labor, dc.detail_burden, dc.detail_service;

-- Diagnostic: why did the ledger join return NULL?
-- 1) Show all WIP_ISSUE_DIST rows for the work order regardless of posting date.
-- 2) Compare the WORKORDER_* key shapes between WIP_LABOR_DETAIL and WIP_ISSUE_DIST.
SELECT 'WIP_ISSUE_DIST rows' AS diagnostic, d.WORKORDER_TYPE, d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID, d.WORKORDER_SPLIT_ID, d.WORKORDER_SUB_ID,
       d.dist_no, d.POSTING_DATE, d.GL_ACCOUNT_ID, a.DESCRIPTION, d.AMOUNT_TYPE, d.AMOUNT
FROM WIP_ISSUE_DIST d (nolock)
JOIN account a (nolock) ON a.id = d.GL_ACCOUNT_ID
WHERE d.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
ORDER BY d.POSTING_DATE, d.dist_no, d.GL_ACCOUNT_ID;

SELECT 'WIP_LABOR_DETAIL keys' AS diagnostic, WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
       COUNT(DISTINCT dist_no) AS distinct_dist_count, MIN(dist_no) AS min_dist, MAX(dist_no) AS max_dist
FROM WIP_LABOR_DETAIL
WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID
GROUP BY WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID;

SELECT 'WIP_ISSUE_DIST keys' AS diagnostic, WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
       COUNT(DISTINCT dist_no) AS distinct_dist_count, MIN(dist_no) AS min_dist, MAX(dist_no) AS max_dist,
       MIN(POSTING_DATE) AS min_posting_date, MAX(POSTING_DATE) AS max_posting_date
FROM WIP_ISSUE_DIST
WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID
GROUP BY WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID;

-- Fallback comparison: sum ledger amounts at WORKORDER_BASE_ID level only.
-- If this matches the calculated delta but the full-key join did not, the issue is a key-shape mismatch.
WITH latest_labor AS (
    SELECT TOP 1 WITH TIES
        WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, WORKORDER_TYPE, dist_no
    FROM WIP_LABOR_DETAIL
    WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    ORDER BY ROW_NUMBER() OVER (
        PARTITION BY WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, WORKORDER_TYPE
        ORDER BY dist_no DESC
    )
), calc_total AS (
    SELECT
        d.WORKORDER_BASE_ID,
        SUM(d.ACT_LABOR_COST + d.ACT_BURDEN_COST) AS labor_burden_at_latest_dist
    FROM latest_labor l
    JOIN WIP_LABOR_DETAIL d
        ON d.WORKORDER_BASE_ID = l.WORKORDER_BASE_ID
        AND d.WORKORDER_LOT_ID = l.WORKORDER_LOT_ID
        AND d.WORKORDER_SPLIT_ID = l.WORKORDER_SPLIT_ID
        AND d.WORKORDER_SUB_ID = l.WORKORDER_SUB_ID
        AND d.WORKORDER_TYPE = l.WORKORDER_TYPE
        AND d.dist_no = l.dist_no
    GROUP BY d.WORKORDER_BASE_ID
), ledger_base AS (
    SELECT
        WORKORDER_BASE_ID,
        SUM(CASE WHEN AMOUNT_TYPE = 'DR' THEN AMOUNT ELSE -AMOUNT END) AS ledger_total_by_base_id,
        COUNT(*) AS ledger_row_count,
        STRING_AGG(CAST(dist_no AS NVARCHAR(10)), ',') AS dist_nos
    FROM WIP_ISSUE_DIST d
    JOIN account a ON a.id = d.GL_ACCOUNT_ID
    WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID
      AND a.id IN ('163','6041','6041.1','6042','6042.1','6043','6043.1','6045','6045.1')
    GROUP BY WORKORDER_BASE_ID
)
SELECT
    c.WORKORDER_BASE_ID,
    c.labor_burden_at_latest_dist,
    l.ledger_total_by_base_id,
    l.ledger_row_count,
    l.dist_nos,
    c.labor_burden_at_latest_dist - ISNULL(l.ledger_total_by_base_id, 0) AS variance,
    CASE WHEN ABS(c.labor_burden_at_latest_dist - ISNULL(l.ledger_total_by_base_id, 0)) < 0.01 THEN 'MATCH' ELSE 'MISMATCH' END AS status
FROM calc_total c
LEFT JOIN ledger_base l ON c.WORKORDER_BASE_ID = l.WORKORDER_BASE_ID;

-- Direct comparison of WIP_ISSUE_DIST labor+burden total to the WIP_LABOR_DETAIL latest dist.
-- No posting-date filter: the ledger rows for this WO are dated 2025-01-31 to 2026-01-31.
SELECT
    @WORKORDER_BASE_ID AS WORKORDER_BASE_ID,
    SUM(CASE WHEN AMOUNT_TYPE = 'DR' THEN AMOUNT ELSE -AMOUNT END) AS wip_issue_dist_labor_burden_total,
    6033.84 AS wip_labor_detail_latest_labor_burden,
    SUM(CASE WHEN AMOUNT_TYPE = 'DR' THEN AMOUNT ELSE -AMOUNT END) - 6033.84 AS variance_vs_labor_detail
FROM WIP_ISSUE_DIST d
JOIN account a ON a.id = d.GL_ACCOUNT_ID
WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID
  AND a.id IN ('163','6041','6041.1','6042','6042.1','6043','6043.1','6045','6045.1');

-- Material-only test: compare WIP_ISSUE_DETAIL material to WIP_ISSUE_DIST material-related GL accounts.
-- Screenshot total (9263.71) minus labor+burden detail (6033.84) implies 3229.87 of material/overhead.
WITH latest_issue AS (
    SELECT TOP 1 WITH TIES
        WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, WORKORDER_TYPE, dist_no
    FROM WIP_ISSUE_DETAIL
    WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    ORDER BY ROW_NUMBER() OVER (
        PARTITION BY WORKORDER_BASE_ID, WORKORDER_LOT_ID, WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, WORKORDER_TYPE
        ORDER BY dist_no DESC
    )
)
SELECT
    'WIP_ISSUE_DETAIL material at latest dist' AS source,
    SUM(d.ACT_MATERIAL_COST) AS material_amount
FROM latest_issue li
JOIN WIP_ISSUE_DETAIL d
    ON d.WORKORDER_BASE_ID = li.WORKORDER_BASE_ID
    AND d.WORKORDER_LOT_ID = li.WORKORDER_LOT_ID
    AND d.WORKORDER_SPLIT_ID = li.WORKORDER_SPLIT_ID
    AND d.WORKORDER_SUB_ID = li.WORKORDER_SUB_ID
    AND d.WORKORDER_TYPE = li.WORKORDER_TYPE
    AND d.dist_no = li.dist_no

UNION ALL

SELECT
    'WIP_ISSUE_DIST material accounts total' AS source,
    SUM(CASE WHEN d.AMOUNT_TYPE = 'DR' THEN d.AMOUNT ELSE -d.AMOUNT END) AS material_amount
FROM WIP_ISSUE_DIST d
JOIN account a ON a.id = d.GL_ACCOUNT_ID
WHERE d.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
  AND a.id NOT IN ('163','6041','6041.1','6042','6042.1','6043','6043.1','6045','6045.1');





