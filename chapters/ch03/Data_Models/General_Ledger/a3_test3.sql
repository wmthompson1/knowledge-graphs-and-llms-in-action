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
--
-- Inputs:
--   @WORKORDER_BASE_ID           - the work order to investigate
--   @LABOR_ACCOUNTS              - labor WIP GL accounts
--   @BURDEN_ACCOUNTS             - burden WIP GL accounts
--   @SERVICE_ACCOUNTS            - service WIP GL accounts (optional)
--
-- Output:
--   Multiple result sets:
--     1. Raw WIP_ISSUE_DIST rows with signed amounts
--     2. Component deltas from detail tables
--     3. Component vs ledger comparison
--     4. Cost Analysis three-layer reconciliation
--     5. Key-shape diagnostic
-- ============================================================================

declare @WORKORDER_BASE_ID nvarchar(50) = '1771611';

-- Site-specific GL account lists. Verify against Live.dbo.ACCOUNT before use.
declare @LABOR_ACCOUNTS   table (id nvarchar(50));
declare @BURDEN_ACCOUNTS  table (id nvarchar(50));
declare @SERVICE_ACCOUNTS table (id nvarchar(50));

insert into @LABOR_ACCOUNTS   values ('163'),('6041'),('6041.1'),('6042'),('6042.1');
insert into @BURDEN_ACCOUNTS  values ('6043'),('6043.1'),('6045'),('6045.1');
-- insert into @SERVICE_ACCOUNTS values (...);  -- populate if known

-- ============================================================================
-- 1. Raw WIP_ISSUE_DIST dump with signed amounts
--    DR = positive (increase WIP), CR = negative (decrease WIP)
-- ============================================================================
select
    d.WORKORDER_TYPE,
    d.WORKORDER_BASE_ID,
    d.WORKORDER_LOT_ID,
    d.WORKORDER_SPLIT_ID,
    d.WORKORDER_SUB_ID,
    d.dist_no,
    d.POSTING_DATE,
    d.GL_ACCOUNT_ID,
    a.DESCRIPTION,
    d.AMOUNT_TYPE,
    d.AMOUNT,
    case when d.AMOUNT_TYPE = 'DR' then d.AMOUNT else -d.AMOUNT end as signed_amount
from Live.dbo.WIP_ISSUE_DIST d (nolock)
join Live.dbo.account a (nolock) on a.id = d.GL_ACCOUNT_ID
where (d.WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
order by d.POSTING_DATE, d.dist_no, d.GL_ACCOUNT_ID;

-- ============================================================================
-- 2. Component deltas from detail tables (latest dist minus previous dist)
-- ============================================================================
with latest_issue as (
    select top 1 with ties
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no
    from Live.dbo.WIP_ISSUE_DETAIL
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    order by row_number() over (
        partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
        order by dist_no desc
    )
),
prev_issue as (
    select
        i.WORKORDER_TYPE, i.WORKORDER_BASE_ID, i.WORKORDER_LOT_ID,
        i.WORKORDER_SPLIT_ID, i.WORKORDER_SUB_ID,
        i.dist_no as latest_dist_no,
        max(d.dist_no) as prev_dist_no
    from latest_issue i
    join Live.dbo.WIP_ISSUE_DETAIL d
        on d.WORKORDER_TYPE = i.WORKORDER_TYPE
        and d.WORKORDER_BASE_ID = i.WORKORDER_BASE_ID
        and d.WORKORDER_LOT_ID = i.WORKORDER_LOT_ID
        and d.WORKORDER_SPLIT_ID = i.WORKORDER_SPLIT_ID
        and d.WORKORDER_SUB_ID = i.WORKORDER_SUB_ID
        and d.dist_no < i.dist_no
    group by
        i.WORKORDER_TYPE, i.WORKORDER_BASE_ID, i.WORKORDER_LOT_ID,
        i.WORKORDER_SPLIT_ID, i.WORKORDER_SUB_ID, i.dist_no
),
latest_labor as (
    select top 1 with ties
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no
    from Live.dbo.WIP_LABOR_DETAIL
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null )
    order by row_number() over (
        partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
        order by dist_no desc
    )
),
prev_labor as (
    select
        l.WORKORDER_TYPE, l.WORKORDER_BASE_ID, l.WORKORDER_LOT_ID,
        l.WORKORDER_SPLIT_ID, l.WORKORDER_SUB_ID,
        l.dist_no as latest_dist_no,
        max(d.dist_no) as prev_dist_no
    from latest_labor l
    join Live.dbo.WIP_LABOR_DETAIL d
        on d.WORKORDER_TYPE = l.WORKORDER_TYPE
        and d.WORKORDER_BASE_ID = l.WORKORDER_BASE_ID
        and d.WORKORDER_LOT_ID = l.WORKORDER_LOT_ID
        and d.WORKORDER_SPLIT_ID = l.WORKORDER_SPLIT_ID
        and d.WORKORDER_SUB_ID = l.WORKORDER_SUB_ID
        and d.dist_no < l.dist_no
    group by
        l.WORKORDER_TYPE, l.WORKORDER_BASE_ID, l.WORKORDER_LOT_ID,
        l.WORKORDER_SPLIT_ID, l.WORKORDER_SUB_ID, l.dist_no
),
latest_service as (
    select top 1 with ties
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no
    from Live.dbo.WIP_SERVICE_DETAIL
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    order by row_number() over (
        partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
        order by dist_no desc
    )
),
prev_service as (
    select
        s.WORKORDER_TYPE, s.WORKORDER_BASE_ID, s.WORKORDER_LOT_ID,
        s.WORKORDER_SPLIT_ID, s.WORKORDER_SUB_ID,
        s.dist_no as latest_dist_no,
        max(d.dist_no) as prev_dist_no
    from latest_service s
    join Live.dbo.WIP_SERVICE_DETAIL d
        on d.WORKORDER_TYPE = s.WORKORDER_TYPE
        and d.WORKORDER_BASE_ID = s.WORKORDER_BASE_ID
        and d.WORKORDER_LOT_ID = s.WORKORDER_LOT_ID
        and d.WORKORDER_SPLIT_ID = s.WORKORDER_SPLIT_ID
        and d.WORKORDER_SUB_ID = s.WORKORDER_SUB_ID
        and d.dist_no < s.dist_no
    group by
        s.WORKORDER_TYPE, s.WORKORDER_BASE_ID, s.WORKORDER_LOT_ID,
        s.WORKORDER_SPLIT_ID, s.WORKORDER_SUB_ID, s.dist_no
),
issue_delta as (
    select
        i.WORKORDER_TYPE, i.WORKORDER_BASE_ID, i.WORKORDER_LOT_ID,
        i.WORKORDER_SPLIT_ID, i.WORKORDER_SUB_ID,
        sum(i_d.ACT_MATERIAL_COST - coalesce(prev.ACT_MATERIAL_COST, 0)) as material_delta,
        sum(i_d.ACT_LABOR_COST   - coalesce(prev.ACT_LABOR_COST, 0))   as labor_delta_in_issue,
        sum(i_d.ACT_BURDEN_COST  - coalesce(prev.ACT_BURDEN_COST, 0))  as burden_delta_in_issue,
        sum(i_d.ACT_SERVICE_COST - coalesce(prev.ACT_SERVICE_COST, 0)) as service_delta_in_issue
    from latest_issue i
    join Live.dbo.WIP_ISSUE_DETAIL i_d
        on i_d.WORKORDER_TYPE = i.WORKORDER_TYPE
        and i_d.WORKORDER_BASE_ID = i.WORKORDER_BASE_ID
        and i_d.WORKORDER_LOT_ID = i.WORKORDER_LOT_ID
        and i_d.WORKORDER_SPLIT_ID = i.WORKORDER_SPLIT_ID
        and i_d.WORKORDER_SUB_ID = i.WORKORDER_SUB_ID
        and i_d.dist_no = i.dist_no
    left join prev_issue p
        on p.WORKORDER_TYPE = i.WORKORDER_TYPE
        and p.WORKORDER_BASE_ID = i.WORKORDER_BASE_ID
        and p.WORKORDER_LOT_ID = i.WORKORDER_LOT_ID
        and p.WORKORDER_SPLIT_ID = i.WORKORDER_SPLIT_ID
        and p.WORKORDER_SUB_ID = i.WORKORDER_SUB_ID
    left join Live.dbo.WIP_ISSUE_DETAIL prev
        on prev.WORKORDER_TYPE = i.WORKORDER_TYPE
        and prev.WORKORDER_BASE_ID = i.WORKORDER_BASE_ID
        and prev.WORKORDER_LOT_ID = i.WORKORDER_LOT_ID
        and prev.WORKORDER_SPLIT_ID = i.WORKORDER_SPLIT_ID
        and prev.WORKORDER_SUB_ID = i.WORKORDER_SUB_ID
        and prev.dist_no = p.prev_dist_no
    group by
        i.WORKORDER_TYPE, i.WORKORDER_BASE_ID, i.WORKORDER_LOT_ID,
        i.WORKORDER_SPLIT_ID, i.WORKORDER_SUB_ID
),
labor_delta as (
    select
        l.WORKORDER_TYPE, l.WORKORDER_BASE_ID, l.WORKORDER_LOT_ID,
        l.WORKORDER_SPLIT_ID, l.WORKORDER_SUB_ID,
        sum(l_d.ACT_LABOR_COST  - coalesce(prev.ACT_LABOR_COST, 0))  as labor_delta,
        sum(l_d.ACT_BURDEN_COST - coalesce(prev.ACT_BURDEN_COST, 0)) as burden_delta
    from latest_labor l
    join Live.dbo.WIP_LABOR_DETAIL l_d
        on l_d.WORKORDER_TYPE = l.WORKORDER_TYPE
        and l_d.WORKORDER_BASE_ID = l.WORKORDER_BASE_ID
        and l_d.WORKORDER_LOT_ID = l.WORKORDER_LOT_ID
        and l_d.WORKORDER_SPLIT_ID = l.WORKORDER_SPLIT_ID
        and l_d.WORKORDER_SUB_ID = l.WORKORDER_SUB_ID
        and l_d.dist_no = l.dist_no
    left join prev_labor p
        on p.WORKORDER_TYPE = l.WORKORDER_TYPE
        and p.WORKORDER_BASE_ID = l.WORKORDER_BASE_ID
        and p.WORKORDER_LOT_ID = l.WORKORDER_LOT_ID
        and p.WORKORDER_SPLIT_ID = l.WORKORDER_SPLIT_ID
        and p.WORKORDER_SUB_ID = l.WORKORDER_SUB_ID
    left join Live.dbo.WIP_LABOR_DETAIL prev
        on prev.WORKORDER_TYPE = l.WORKORDER_TYPE
        and prev.WORKORDER_BASE_ID = l.WORKORDER_BASE_ID
        and prev.WORKORDER_LOT_ID = l.WORKORDER_LOT_ID
        and prev.WORKORDER_SPLIT_ID = l.WORKORDER_SPLIT_ID
        and prev.WORKORDER_SUB_ID = l.WORKORDER_SUB_ID
        and prev.dist_no = p.prev_dist_no
    group by
        l.WORKORDER_TYPE, l.WORKORDER_BASE_ID, l.WORKORDER_LOT_ID,
        l.WORKORDER_SPLIT_ID, l.WORKORDER_SUB_ID
),
service_delta as (
    select
        s.WORKORDER_TYPE, s.WORKORDER_BASE_ID, s.WORKORDER_LOT_ID,
        s.WORKORDER_SPLIT_ID, s.WORKORDER_SUB_ID,
        sum(s_d.ACT_SERVICE_COST - coalesce(prev.ACT_SERVICE_COST, 0)) as service_delta
    from latest_service s
    join Live.dbo.WIP_SERVICE_DETAIL s_d
        on s_d.WORKORDER_TYPE = s.WORKORDER_TYPE
        and s_d.WORKORDER_BASE_ID = s.WORKORDER_BASE_ID
        and s_d.WORKORDER_LOT_ID = s.WORKORDER_LOT_ID
        and s_d.WORKORDER_SPLIT_ID = s.WORKORDER_SPLIT_ID
        and s_d.WORKORDER_SUB_ID = s.WORKORDER_SUB_ID
        and s_d.dist_no = s.dist_no
    left join prev_service p
        on p.WORKORDER_TYPE = s.WORKORDER_TYPE
        and p.WORKORDER_BASE_ID = s.WORKORDER_BASE_ID
        and p.WORKORDER_LOT_ID = s.WORKORDER_LOT_ID
        and p.WORKORDER_SPLIT_ID = s.WORKORDER_SPLIT_ID
        and p.WORKORDER_SUB_ID = s.WORKORDER_SUB_ID
    left join Live.dbo.WIP_SERVICE_DETAIL prev
        on prev.WORKORDER_TYPE = s.WORKORDER_TYPE
        and prev.WORKORDER_BASE_ID = s.WORKORDER_BASE_ID
        and prev.WORKORDER_LOT_ID = s.WORKORDER_LOT_ID
        and prev.WORKORDER_SPLIT_ID = s.WORKORDER_SPLIT_ID
        and prev.WORKORDER_SUB_ID = s.WORKORDER_SUB_ID
        and prev.dist_no = p.prev_dist_no
    group by
        s.WORKORDER_TYPE, s.WORKORDER_BASE_ID, s.WORKORDER_LOT_ID,
        s.WORKORDER_SPLIT_ID, s.WORKORDER_SUB_ID
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

-- ============================================================================
-- 3. Component vs ledger comparison
-- ============================================================================
with ledger_by_component as (
    select
        d.WORKORDER_TYPE, d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID,
        d.WORKORDER_SPLIT_ID, d.WORKORDER_SUB_ID,
        sum(case when la.id is not null
                 then case when d.AMOUNT_TYPE = 'DR' then d.AMOUNT else -d.AMOUNT end
                 else 0 end) as labor_ledger,
        sum(case when ba.id is not null
                 then case when d.AMOUNT_TYPE = 'DR' then d.AMOUNT else -d.AMOUNT end
                 else 0 end) as burden_ledger,
        sum(case when sa.id is not null
                 then case when d.AMOUNT_TYPE = 'DR' then d.AMOUNT else -d.AMOUNT end
                 else 0 end) as service_ledger,
        sum(case when la.id is null and ba.id is null and sa.id is null
                 then case when d.AMOUNT_TYPE = 'DR' then d.AMOUNT else -d.AMOUNT end
                 else 0 end) as material_ledger
    from Live.dbo.WIP_ISSUE_DIST d (nolock)
    left join @LABOR_ACCOUNTS la   on la.id = d.GL_ACCOUNT_ID
    left join @BURDEN_ACCOUNTS ba  on ba.id = d.GL_ACCOUNT_ID
    left join @SERVICE_ACCOUNTS sa on sa.id = d.GL_ACCOUNT_ID
    where (d.WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    group by
        d.WORKORDER_TYPE, d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID,
        d.WORKORDER_SPLIT_ID, d.WORKORDER_SUB_ID
)
select
    'Labor'   as component, labor_ledger   as ledger_amount from ledger_by_component
union all
select
    'Burden'  as component, burden_ledger  as ledger_amount from ledger_by_component
union all
select
    'Service' as component, service_ledger as ledger_amount from ledger_by_component
union all
select
    'Material' as component, material_ledger as ledger_amount from ledger_by_component;

-- ============================================================================
-- 4. Cost Analysis three-layer reconciliation
--    Total Transactions (WORK_ORDER)
--    Total Trans Detail (_DETAIL tables)
--    Total Posted (WIP_ISSUE_DIST)
--
-- Note: WIP_PAYB_DETAIL and SPLIT_TRANS are included per the Costing Tools
-- flow table. Field names are the standard VISUAL ERP conventions; adjust if
-- your site uses different column names.
-- ============================================================================
with latest_labor as (
    select top 1 with ties
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no
    from Live.dbo.WIP_LABOR_DETAIL
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    order by row_number() over (
        partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
        order by dist_no desc
    )
),
latest_issue as (
    select top 1 with ties
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no
    from Live.dbo.WIP_ISSUE_DETAIL
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    order by row_number() over (
        partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
        order by dist_no desc
    )
),
latest_service as (
    select top 1 with ties
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no
    from Live.dbo.WIP_SERVICE_DETAIL
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    order by row_number() over (
        partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
        order by dist_no desc
    )
),
latest_payb as (
    select top 1 with ties
        WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID, WORKORDER_SUB_ID, dist_no
    from Live.dbo.WIP_PAYB_DETAIL
    where (WORKORDER_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    order by row_number() over (
        partition by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
                     WORKORDER_SPLIT_ID, WORKORDER_SUB_ID
        order by dist_no desc
    )
),
split_from as (
    -- Outgoing split transactions reduce this work order's WIP.
    select
        FROM_WO_TYPE   as WORKORDER_TYPE,
        FROM_WO_BASE_ID as WORKORDER_BASE_ID,
        FROM_WO_LOT_ID  as WORKORDER_LOT_ID,
        FROM_WO_SPLIT_ID as WORKORDER_SPLIT_ID,
        FROM_WO_SUB_ID  as WORKORDER_SUB_ID,
        -sum(ACT_MATERIAL_COST + ACT_LABOR_COST + ACT_BURDEN_COST + ACT_SERVICE_COST) as split_total
    from Live.dbo.SPLIT_TRANS
    where (FROM_WO_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    group by
        FROM_WO_TYPE, FROM_WO_BASE_ID, FROM_WO_LOT_ID,
        FROM_WO_SPLIT_ID, FROM_WO_SUB_ID
),
split_to as (
    -- Incoming split transactions increase this work order's WIP.
    select
        TO_WO_TYPE   as WORKORDER_TYPE,
        TO_WO_BASE_ID as WORKORDER_BASE_ID,
        TO_WO_LOT_ID  as WORKORDER_LOT_ID,
        TO_WO_SPLIT_ID as WORKORDER_SPLIT_ID,
        TO_WO_SUB_ID  as WORKORDER_SUB_ID,
        sum(ACT_MATERIAL_COST + ACT_LABOR_COST + ACT_BURDEN_COST + ACT_SERVICE_COST) as split_total
    from Live.dbo.SPLIT_TRANS
    where (TO_WO_BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
    group by
        TO_WO_TYPE, TO_WO_BASE_ID, TO_WO_LOT_ID,
        TO_WO_SPLIT_ID, TO_WO_SUB_ID
),
split_net as (
    select
        coalesce(f.WORKORDER_TYPE, t.WORKORDER_TYPE) as WORKORDER_TYPE,
        coalesce(f.WORKORDER_BASE_ID, t.WORKORDER_BASE_ID) as WORKORDER_BASE_ID,
        coalesce(f.WORKORDER_LOT_ID, t.WORKORDER_LOT_ID) as WORKORDER_LOT_ID,
        coalesce(f.WORKORDER_SPLIT_ID, t.WORKORDER_SPLIT_ID) as WORKORDER_SPLIT_ID,
        coalesce(f.WORKORDER_SUB_ID, t.WORKORDER_SUB_ID) as WORKORDER_SUB_ID,
        isnull(f.split_total, 0) + isnull(t.split_total, 0) as split_total
    from split_from f
    full outer join split_to t
        on t.WORKORDER_TYPE = f.WORKORDER_TYPE and t.WORKORDER_BASE_ID = f.WORKORDER_BASE_ID
        and t.WORKORDER_LOT_ID = f.WORKORDER_LOT_ID and t.WORKORDER_SPLIT_ID = f.WORKORDER_SPLIT_ID
        and t.WORKORDER_SUB_ID = f.WORKORDER_SUB_ID
),
wo_summary as (
    select
        [TYPE]   as WORKORDER_TYPE,
        BASE_ID  as WORKORDER_BASE_ID,
        LOT_ID   as WORKORDER_LOT_ID,
        SPLIT_ID as WORKORDER_SPLIT_ID,
        SUB_ID   as WORKORDER_SUB_ID,
        isnull(ACT_MATERIAL_COST, 0) + isnull(ACT_LABOR_COST, 0)
            + isnull(ACT_BURDEN_COST, 0) + isnull(ACT_SERVICE_COST, 0) as wo_total
    from Live.dbo.WORK_ORDER
    where (BASE_ID = @WORKORDER_BASE_ID or @WORKORDER_BASE_ID is null)
),
-- Aggregate each detail source separately before merging.  This avoids
-- accidental fan-out from joining detail rows to a chain of latest CTEs.
--
-- Component mapping (matches Costing Tools Cost Analysis / a3_test3.2.sql):
--   material -> WIP_ISSUE_DETAIL.ACT_MATERIAL_COST
--   labor    -> WIP_LABOR_DETAIL.ACT_LABOR_COST
--   burden   -> WIP_LABOR_DETAIL.ACT_BURDEN_COST
--   service  -> WIP_SERVICE_DETAIL.ACT_SERVICE_COST
--   payable  -> WIP_PAYB_DETAIL (all four cost fields)
issue_agg as (
    select i.WORKORDER_TYPE, i.WORKORDER_BASE_ID, i.WORKORDER_LOT_ID,
           i.WORKORDER_SPLIT_ID, i.WORKORDER_SUB_ID,
           sum(i_d.ACT_MATERIAL_COST) as issue_total
    from latest_issue i
    join Live.dbo.WIP_ISSUE_DETAIL i_d
        on i_d.WORKORDER_TYPE = i.WORKORDER_TYPE
        and i_d.WORKORDER_BASE_ID = i.WORKORDER_BASE_ID
        and i_d.WORKORDER_LOT_ID = i.WORKORDER_LOT_ID
        and i_d.WORKORDER_SPLIT_ID = i.WORKORDER_SPLIT_ID
        and i_d.WORKORDER_SUB_ID = i.WORKORDER_SUB_ID
        and i_d.dist_no = i.dist_no
    group by i.WORKORDER_TYPE, i.WORKORDER_BASE_ID, i.WORKORDER_LOT_ID,
             i.WORKORDER_SPLIT_ID, i.WORKORDER_SUB_ID
),
labor_agg as (
    select l.WORKORDER_TYPE, l.WORKORDER_BASE_ID, l.WORKORDER_LOT_ID,
           l.WORKORDER_SPLIT_ID, l.WORKORDER_SUB_ID,
           sum(l_d.ACT_LABOR_COST + l_d.ACT_BURDEN_COST) as labor_total
    from latest_labor l
    join Live.dbo.WIP_LABOR_DETAIL l_d
        on l_d.WORKORDER_TYPE = l.WORKORDER_TYPE
        and l_d.WORKORDER_BASE_ID = l.WORKORDER_BASE_ID
        and l_d.WORKORDER_LOT_ID = l.WORKORDER_LOT_ID
        and l_d.WORKORDER_SPLIT_ID = l.WORKORDER_SPLIT_ID
        and l_d.WORKORDER_SUB_ID = l.WORKORDER_SUB_ID
        and l_d.dist_no = l.dist_no
    group by l.WORKORDER_TYPE, l.WORKORDER_BASE_ID, l.WORKORDER_LOT_ID,
             l.WORKORDER_SPLIT_ID, l.WORKORDER_SUB_ID
),
service_agg as (
    select s.WORKORDER_TYPE, s.WORKORDER_BASE_ID, s.WORKORDER_LOT_ID,
           s.WORKORDER_SPLIT_ID, s.WORKORDER_SUB_ID,
           sum(s_d.ACT_SERVICE_COST) as service_total
    from latest_service s
    join Live.dbo.WIP_SERVICE_DETAIL s_d
        on s_d.WORKORDER_TYPE = s.WORKORDER_TYPE
        and s_d.WORKORDER_BASE_ID = s.WORKORDER_BASE_ID
        and s_d.WORKORDER_LOT_ID = s.WORKORDER_LOT_ID
        and s_d.WORKORDER_SPLIT_ID = s.WORKORDER_SPLIT_ID
        and s_d.WORKORDER_SUB_ID = s.WORKORDER_SUB_ID
        and s_d.dist_no = s.dist_no
    group by s.WORKORDER_TYPE, s.WORKORDER_BASE_ID, s.WORKORDER_LOT_ID,
             s.WORKORDER_SPLIT_ID, s.WORKORDER_SUB_ID
),
payb_agg as (
    select p.WORKORDER_TYPE, p.WORKORDER_BASE_ID, p.WORKORDER_LOT_ID,
           p.WORKORDER_SPLIT_ID, p.WORKORDER_SUB_ID,
           sum(p_d.ACT_MATERIAL_COST + p_d.ACT_LABOR_COST
               + p_d.ACT_BURDEN_COST + p_d.ACT_SERVICE_COST) as payable_total
    from latest_payb p
    join Live.dbo.WIP_PAYB_DETAIL p_d
        on p_d.WORKORDER_TYPE = p.WORKORDER_TYPE
        and p_d.WORKORDER_BASE_ID = p.WORKORDER_BASE_ID
        and p_d.WORKORDER_LOT_ID = p.WORKORDER_LOT_ID
        and p_d.WORKORDER_SPLIT_ID = p.WORKORDER_SPLIT_ID
        and p_d.WORKORDER_SUB_ID = p.WORKORDER_SUB_ID
        and p_d.dist_no = p.dist_no
    group by p.WORKORDER_TYPE, p.WORKORDER_BASE_ID, p.WORKORDER_LOT_ID,
             p.WORKORDER_SPLIT_ID, p.WORKORDER_SUB_ID
),
detail_summary as (
    select
        coalesce(i.WORKORDER_TYPE, l.WORKORDER_TYPE, s.WORKORDER_TYPE,
                 p.WORKORDER_TYPE, sp.WORKORDER_TYPE) as WORKORDER_TYPE,
        coalesce(i.WORKORDER_BASE_ID, l.WORKORDER_BASE_ID, s.WORKORDER_BASE_ID,
                 p.WORKORDER_BASE_ID, sp.WORKORDER_BASE_ID) as WORKORDER_BASE_ID,
        coalesce(i.WORKORDER_LOT_ID, l.WORKORDER_LOT_ID, s.WORKORDER_LOT_ID,
                 p.WORKORDER_LOT_ID, sp.WORKORDER_LOT_ID) as WORKORDER_LOT_ID,
        coalesce(i.WORKORDER_SPLIT_ID, l.WORKORDER_SPLIT_ID, s.WORKORDER_SPLIT_ID,
                 p.WORKORDER_SPLIT_ID, sp.WORKORDER_SPLIT_ID) as WORKORDER_SPLIT_ID,
        coalesce(i.WORKORDER_SUB_ID, l.WORKORDER_SUB_ID, s.WORKORDER_SUB_ID,
                 p.WORKORDER_SUB_ID, sp.WORKORDER_SUB_ID) as WORKORDER_SUB_ID,
        isnull(i.issue_total, 0)    as issue_total,
        isnull(l.labor_total, 0)    as labor_total,
        isnull(s.service_total, 0)  as service_total,
        isnull(p.payable_total, 0)  as payable_total,
        isnull(sp.split_total, 0)   as split_total
    from issue_agg i
    full outer join labor_agg l
        on l.WORKORDER_TYPE = i.WORKORDER_TYPE and l.WORKORDER_BASE_ID = i.WORKORDER_BASE_ID
        and l.WORKORDER_LOT_ID = i.WORKORDER_LOT_ID and l.WORKORDER_SPLIT_ID = i.WORKORDER_SPLIT_ID
        and l.WORKORDER_SUB_ID = i.WORKORDER_SUB_ID
    full outer join service_agg s
        on s.WORKORDER_TYPE = coalesce(l.WORKORDER_TYPE, i.WORKORDER_TYPE)
        and s.WORKORDER_BASE_ID = coalesce(l.WORKORDER_BASE_ID, i.WORKORDER_BASE_ID)
        and s.WORKORDER_LOT_ID = coalesce(l.WORKORDER_LOT_ID, i.WORKORDER_LOT_ID)
        and s.WORKORDER_SPLIT_ID = coalesce(l.WORKORDER_SPLIT_ID, i.WORKORDER_SPLIT_ID)
        and s.WORKORDER_SUB_ID = coalesce(l.WORKORDER_SUB_ID, i.WORKORDER_SUB_ID)
    full outer join payb_agg p
        on p.WORKORDER_TYPE = coalesce(l.WORKORDER_TYPE, i.WORKORDER_TYPE, s.WORKORDER_TYPE)
        and p.WORKORDER_BASE_ID = coalesce(l.WORKORDER_BASE_ID, i.WORKORDER_BASE_ID, s.WORKORDER_BASE_ID)
        and p.WORKORDER_LOT_ID = coalesce(l.WORKORDER_LOT_ID, i.WORKORDER_LOT_ID, s.WORKORDER_LOT_ID)
        and p.WORKORDER_SPLIT_ID = coalesce(l.WORKORDER_SPLIT_ID, i.WORKORDER_SPLIT_ID, s.WORKORDER_SPLIT_ID)
        and p.WORKORDER_SUB_ID = coalesce(l.WORKORDER_SUB_ID, i.WORKORDER_SUB_ID, s.WORKORDER_SUB_ID)
    full outer join split_net sp
        on sp.WORKORDER_TYPE = coalesce(l.WORKORDER_TYPE, i.WORKORDER_TYPE, s.WORKORDER_TYPE, p.WORKORDER_TYPE)
        and sp.WORKORDER_BASE_ID = coalesce(l.WORKORDER_BASE_ID, i.WORKORDER_BASE_ID, s.WORKORDER_BASE_ID, p.WORKORDER_BASE_ID)
        and sp.WORKORDER_LOT_ID = coalesce(l.WORKORDER_LOT_ID, i.WORKORDER_LOT_ID, s.WORKORDER_LOT_ID, p.WORKORDER_LOT_ID)
        and sp.WORKORDER_SPLIT_ID = coalesce(l.WORKORDER_SPLIT_ID, i.WORKORDER_SPLIT_ID, s.WORKORDER_SPLIT_ID, p.WORKORDER_SPLIT_ID)
        and sp.WORKORDER_SUB_ID = coalesce(l.WORKORDER_SUB_ID, i.WORKORDER_SUB_ID, s.WORKORDER_SUB_ID, p.WORKORDER_SUB_ID)
),
ledger_summary as (
    select
        d.WORKORDER_TYPE, d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID,
        d.WORKORDER_SPLIT_ID, d.WORKORDER_SUB_ID,
        sum(case when d.AMOUNT_TYPE = 'DR' then d.AMOUNT else -d.AMOUNT end) as ledger_total
    from Live.dbo.WIP_ISSUE_DIST d
    where d.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    group by
        d.WORKORDER_TYPE, d.WORKORDER_BASE_ID, d.WORKORDER_LOT_ID,
        d.WORKORDER_SPLIT_ID, d.WORKORDER_SUB_ID
)
select
    w.WORKORDER_TYPE, w.WORKORDER_BASE_ID, w.WORKORDER_LOT_ID,
    w.WORKORDER_SPLIT_ID, w.WORKORDER_SUB_ID,
    w.wo_total                                   as [Total Transactions (WORK_ORDER)],
    d.issue_total + d.labor_total + d.service_total
        + d.payable_total + d.split_total        as [Total Trans Detail (_DETAIL tables)],
    l.ledger_total                               as [Total Posted (WIP_ISSUE_DIST)],
    w.wo_total
      - (d.issue_total + d.labor_total + d.service_total
         + d.payable_total + d.split_total)      as variance_transactions_vs_detail,
    (d.issue_total + d.labor_total + d.service_total
         + d.payable_total + d.split_total)
      - isnull(l.ledger_total, 0)                as variance_detail_vs_ledger,
    case when abs(w.wo_total
                  - (d.issue_total + d.labor_total + d.service_total
                     + d.payable_total + d.split_total)) < 0.01
         then 'MATCH' else 'MISMATCH' end        as transactions_detail_status,
    case when abs((d.issue_total + d.labor_total + d.service_total
                     + d.payable_total + d.split_total)
                  - isnull(l.ledger_total, 0)) < 0.01
         then 'MATCH' else 'MISMATCH' end        as detail_ledger_status
from wo_summary w
left join detail_summary d
    on d.WORKORDER_TYPE = w.WORKORDER_TYPE and d.WORKORDER_BASE_ID = w.WORKORDER_BASE_ID
    and d.WORKORDER_LOT_ID = w.WORKORDER_LOT_ID and d.WORKORDER_SPLIT_ID = w.WORKORDER_SPLIT_ID
    and d.WORKORDER_SUB_ID = w.WORKORDER_SUB_ID
left join ledger_summary l
    on l.WORKORDER_TYPE = w.WORKORDER_TYPE and l.WORKORDER_BASE_ID = w.WORKORDER_BASE_ID
    and l.WORKORDER_LOT_ID = w.WORKORDER_LOT_ID and l.WORKORDER_SPLIT_ID = w.WORKORDER_SPLIT_ID
    and l.WORKORDER_SUB_ID = w.WORKORDER_SUB_ID;

-- ============================================================================
-- 5. Key-shape and posting-date diagnostics
-- ============================================================================
select 'WIP_LABOR_DETAIL keys' as diagnostic,
       WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
       WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
       count(distinct dist_no) as distinct_dist_count,
       min(dist_no) as min_dist, max(dist_no) as max_dist
from Live.dbo.WIP_LABOR_DETAIL
where WORKORDER_BASE_ID = @WORKORDER_BASE_ID
group by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
         WORKORDER_SPLIT_ID, WORKORDER_SUB_ID;

select 'WIP_ISSUE_DIST keys' as diagnostic,
       WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
       WORKORDER_SPLIT_ID, WORKORDER_SUB_ID,
       count(distinct dist_no) as distinct_dist_count,
       min(dist_no) as min_dist, max(dist_no) as max_dist,
       min(POSTING_DATE) as min_posting_date, max(POSTING_DATE) as max_posting_date
from Live.dbo.WIP_ISSUE_DIST
where WORKORDER_BASE_ID = @WORKORDER_BASE_ID
group by WORKORDER_TYPE, WORKORDER_BASE_ID, WORKORDER_LOT_ID,
         WORKORDER_SPLIT_ID, WORKORDER_SUB_ID;
