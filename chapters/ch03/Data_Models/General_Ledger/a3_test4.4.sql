-- ============================================================================
-- a3_test4.4.sql — Distribution/account grain reconciliation
-- Purpose: Reconcile WIP detail deltas to WIP_ISSUE_DIST at the grain of
--          work order + GL account + dist_no.  This matches the actual
--          posting grain and avoids key-shape assumptions around SUB_ID.
-- ============================================================================
declare @WORKORDER_BASE_ID nvarchar(50) = '1818464';

-- Site-specific GL account lists. Verify against Live.dbo.ACCOUNT before use.
declare @LABOR_ACCOUNTS   table (id nvarchar(50));
declare @BURDEN_ACCOUNTS  table (id nvarchar(50));
declare @SERVICE_ACCOUNTS table (id nvarchar(50));

insert into @LABOR_ACCOUNTS   values ('163'),('6041'),('6041.1'),('6042'),('6042.1');
insert into @BURDEN_ACCOUNTS  values ('6043'),('6043.1'),('6045'),('6045.1');
-- insert into @SERVICE_ACCOUNTS values (...);

-- ---------------------------------------------------------------------------
-- 1. Ledger side: signed amount per work order + account + dist
-- ---------------------------------------------------------------------------
with ledger as (
    select
        d.WORKORDER_TYPE,
        d.WORKORDER_BASE_ID,
        d.GL_ACCOUNT_ID,
        d.dist_no,
        sum(case when d.AMOUNT_TYPE = 'DR' then d.AMOUNT else -d.AMOUNT end) as ledger_signed
    from Live.dbo.WIP_ISSUE_DIST d
    where d.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    group by
        d.WORKORDER_TYPE, d.WORKORDER_BASE_ID, d.GL_ACCOUNT_ID, d.dist_no
),
-- ---------------------------------------------------------------------------
-- 2. Detail side: derive component per account bucket and dist_no.
--    For each detail table we take the current row's cost and subtract the
--    same cost from the previous dist_no for the same (WO + SUB_ID) key.
--    Rows are then classified by GL account bucket (material/labor/burden/
--    service/payable) so they can be summed to the ledger account grain.
-- ---------------------------------------------------------------------------
issue_with_delta as (
    select
        i.WORKORDER_TYPE,
        i.WORKORDER_BASE_ID,
        i.WORKORDER_LOT_ID,
        i.WORKORDER_SPLIT_ID,
        i.WORKORDER_SUB_ID,
        i.dist_no,
        i.ACT_MATERIAL_COST - coalesce(prev.ACT_MATERIAL_COST, 0) as material_delta
    from Live.dbo.WIP_ISSUE_DETAIL i
    left join Live.dbo.WIP_ISSUE_DETAIL prev
        on prev.WORKORDER_TYPE = i.WORKORDER_TYPE
        and prev.WORKORDER_BASE_ID = i.WORKORDER_BASE_ID
        and isnull(prev.WORKORDER_LOT_ID,'')   = isnull(i.WORKORDER_LOT_ID,'')
        and isnull(prev.WORKORDER_SPLIT_ID,'') = isnull(i.WORKORDER_SPLIT_ID,'')
        and isnull(prev.WORKORDER_SUB_ID,'')   = isnull(i.WORKORDER_SUB_ID,'')
        and prev.dist_no = (
            select max(dist_no)
            from Live.dbo.WIP_ISSUE_DETAIL x
            where x.WORKORDER_TYPE = i.WORKORDER_TYPE
              and x.WORKORDER_BASE_ID = i.WORKORDER_BASE_ID
              and isnull(x.WORKORDER_LOT_ID,'')   = isnull(i.WORKORDER_LOT_ID,'')
              and isnull(x.WORKORDER_SPLIT_ID,'') = isnull(i.WORKORDER_SPLIT_ID,'')
              and isnull(x.WORKORDER_SUB_ID,'')   = isnull(i.WORKORDER_SUB_ID,'')
              and x.dist_no < i.dist_no
        )
    where i.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
),
labor_with_delta as (
    select
        l.WORKORDER_TYPE,
        l.WORKORDER_BASE_ID,
        l.WORKORDER_LOT_ID,
        l.WORKORDER_SPLIT_ID,
        l.WORKORDER_SUB_ID,
        l.dist_no,
        l.ACT_LABOR_COST  - coalesce(prev.ACT_LABOR_COST, 0)  as labor_delta,
        l.ACT_BURDEN_COST - coalesce(prev.ACT_BURDEN_COST, 0) as burden_delta
    from Live.dbo.WIP_LABOR_DETAIL l
    left join Live.dbo.WIP_LABOR_DETAIL prev
        on prev.WORKORDER_TYPE = l.WORKORDER_TYPE
        and prev.WORKORDER_BASE_ID = l.WORKORDER_BASE_ID
        and isnull(prev.WORKORDER_LOT_ID,'')   = isnull(l.WORKORDER_LOT_ID,'')
        and isnull(prev.WORKORDER_SPLIT_ID,'') = isnull(l.WORKORDER_SPLIT_ID,'')
        and isnull(prev.WORKORDER_SUB_ID,'')   = isnull(l.WORKORDER_SUB_ID,'')
        and prev.dist_no = (
            select max(dist_no)
            from Live.dbo.WIP_LABOR_DETAIL x
            where x.WORKORDER_TYPE = l.WORKORDER_TYPE
              and x.WORKORDER_BASE_ID = l.WORKORDER_BASE_ID
              and isnull(x.WORKORDER_LOT_ID,'')   = isnull(l.WORKORDER_LOT_ID,'')
              and isnull(x.WORKORDER_SPLIT_ID,'') = isnull(l.WORKORDER_SPLIT_ID,'')
              and isnull(x.WORKORDER_SUB_ID,'')   = isnull(l.WORKORDER_SUB_ID,'')
              and x.dist_no < l.dist_no
        )
    where l.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
),
service_with_delta as (
    select
        s.WORKORDER_TYPE,
        s.WORKORDER_BASE_ID,
        s.WORKORDER_LOT_ID,
        s.WORKORDER_SPLIT_ID,
        s.WORKORDER_SUB_ID,
        s.dist_no,
        s.ACT_SERVICE_COST - coalesce(prev.ACT_SERVICE_COST, 0) as service_delta
    from Live.dbo.WIP_SERVICE_DETAIL s
    left join Live.dbo.WIP_SERVICE_DETAIL prev
        on prev.WORKORDER_TYPE = s.WORKORDER_TYPE
        and prev.WORKORDER_BASE_ID = s.WORKORDER_BASE_ID
        and isnull(prev.WORKORDER_LOT_ID,'')   = isnull(s.WORKORDER_LOT_ID,'')
        and isnull(prev.WORKORDER_SPLIT_ID,'') = isnull(s.WORKORDER_SPLIT_ID,'')
        and isnull(prev.WORKORDER_SUB_ID,'')   = isnull(s.WORKORDER_SUB_ID,'')
        and prev.dist_no = (
            select max(dist_no)
            from Live.dbo.WIP_SERVICE_DETAIL x
            where x.WORKORDER_TYPE = s.WORKORDER_TYPE
              and x.WORKORDER_BASE_ID = s.WORKORDER_BASE_ID
              and isnull(x.WORKORDER_LOT_ID,'')   = isnull(s.WORKORDER_LOT_ID,'')
              and isnull(x.WORKORDER_SPLIT_ID,'') = isnull(s.WORKORDER_SPLIT_ID,'')
              and isnull(x.WORKORDER_SUB_ID,'')   = isnull(s.WORKORDER_SUB_ID,'')
              and x.dist_no < s.dist_no
        )
    where s.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
),
payb_with_delta as (
    select
        p.WORKORDER_TYPE,
        p.WORKORDER_BASE_ID,
        p.WORKORDER_LOT_ID,
        p.WORKORDER_SPLIT_ID,
        p.WORKORDER_SUB_ID,
        p.dist_no,
        (p.ACT_MATERIAL_COST - coalesce(prev.ACT_MATERIAL_COST, 0))
      + (p.ACT_LABOR_COST    - coalesce(prev.ACT_LABOR_COST, 0))
      + (p.ACT_BURDEN_COST   - coalesce(prev.ACT_BURDEN_COST, 0))
      + (p.ACT_SERVICE_COST  - coalesce(prev.ACT_SERVICE_COST, 0)) as payable_delta
    from Live.dbo.WIP_PAYB_DETAIL p
    left join Live.dbo.WIP_PAYB_DETAIL prev
        on prev.WORKORDER_TYPE = p.WORKORDER_TYPE
        and prev.WORKORDER_BASE_ID = p.WORKORDER_BASE_ID
        and isnull(prev.WORKORDER_LOT_ID,'')   = isnull(p.WORKORDER_LOT_ID,'')
        and isnull(prev.WORKORDER_SPLIT_ID,'') = isnull(p.WORKORDER_SPLIT_ID,'')
        and isnull(prev.WORKORDER_SUB_ID,'')   = isnull(p.WORKORDER_SUB_ID,'')
        and prev.dist_no = (
            select max(dist_no)
            from Live.dbo.WIP_PAYB_DETAIL x
            where x.WORKORDER_TYPE = p.WORKORDER_TYPE
              and x.WORKORDER_BASE_ID = p.WORKORDER_BASE_ID
              and isnull(x.WORKORDER_LOT_ID,'')   = isnull(p.WORKORDER_LOT_ID,'')
              and isnull(x.WORKORDER_SPLIT_ID,'') = isnull(p.WORKORDER_SPLIT_ID,'')
              and isnull(x.WORKORDER_SUB_ID,'')   = isnull(p.WORKORDER_SUB_ID,'')
              and x.dist_no < p.dist_no
        )
    where p.WORKORDER_BASE_ID = @WORKORDER_BASE_ID
),
-- ---------------------------------------------------------------------------
-- 3. Roll detail deltas up to the ledger account grain.
--    For material/service/payable we do not know the exact GL account that
--    was posted, so we use the user-provided account lists to classify
--    labor/burden/service and bucket everything else as material.
-- ---------------------------------------------------------------------------
detail_by_account as (
    -- labor bucket
    select
        i.WORKORDER_TYPE,
        i.WORKORDER_BASE_ID,
        a.id as GL_ACCOUNT_ID,
        i.dist_no,
        sum(i.material_delta) as detail_signed
    from issue_with_delta i
    cross join @LABOR_ACCOUNTS a
    where i.material_delta <> 0
    group by i.WORKORDER_TYPE, i.WORKORDER_BASE_ID, a.id, i.dist_no

    union all

    -- burden bucket
    select
        l.WORKORDER_TYPE,
        l.WORKORDER_BASE_ID,
        a.id as GL_ACCOUNT_ID,
        l.dist_no,
        sum(l.burden_delta) as detail_signed
    from labor_with_delta l
    cross join @BURDEN_ACCOUNTS a
    where l.burden_delta <> 0
    group by l.WORKORDER_TYPE, l.WORKORDER_BASE_ID, a.id, l.dist_no

    union all

    -- service bucket
    select
        s.WORKORDER_TYPE,
        s.WORKORDER_BASE_ID,
        a.id as GL_ACCOUNT_ID,
        s.dist_no,
        sum(s.service_delta) as detail_signed
    from service_with_delta s
    cross join @SERVICE_ACCOUNTS a
    where s.service_delta <> 0
    group by s.WORKORDER_TYPE, s.WORKORDER_BASE_ID, a.id, s.dist_no

    union all

    -- labor part of labor table
    select
        l.WORKORDER_TYPE,
        l.WORKORDER_BASE_ID,
        a.id as GL_ACCOUNT_ID,
        l.dist_no,
        sum(l.labor_delta) as detail_signed
    from labor_with_delta l
    cross join @LABOR_ACCOUNTS a
    where l.labor_delta <> 0
    group by l.WORKORDER_TYPE, l.WORKORDER_BASE_ID, a.id, l.dist_no

    union all

    -- payable bucket — included as its own line per Costing Tools flow
    select
        p.WORKORDER_TYPE,
        p.WORKORDER_BASE_ID,
        'PAYABLE' as GL_ACCOUNT_ID,
        p.dist_no,
        sum(p.payable_delta) as detail_signed
    from payb_with_delta p
    where p.payable_delta <> 0
    group by p.WORKORDER_TYPE, p.WORKORDER_BASE_ID, p.dist_no
),
-- ---------------------------------------------------------------------------
-- 4. Reconcile ledger vs detail at work order + account + dist
-- ---------------------------------------------------------------------------
reconciliation as (
    select
        coalesce(l.WORKORDER_TYPE, d.WORKORDER_TYPE) as WORKORDER_TYPE,
        coalesce(l.WORKORDER_BASE_ID, d.WORKORDER_BASE_ID) as WORKORDER_BASE_ID,
        coalesce(l.GL_ACCOUNT_ID, d.GL_ACCOUNT_ID) as GL_ACCOUNT_ID,
        coalesce(l.dist_no, d.dist_no) as dist_no,
        isnull(l.ledger_signed, 0)   as ledger_signed,
        isnull(d.detail_signed, 0)   as detail_signed,
        isnull(l.ledger_signed, 0) - isnull(d.detail_signed, 0) as variance,
        case when abs(isnull(l.ledger_signed, 0) - isnull(d.detail_signed, 0)) < 0.01
             then 'MATCH' else 'MISMATCH' end as status
    from ledger l
    full outer join detail_by_account d
        on d.WORKORDER_TYPE = l.WORKORDER_TYPE
        and d.WORKORDER_BASE_ID = l.WORKORDER_BASE_ID
        and d.GL_ACCOUNT_ID = l.GL_ACCOUNT_ID
        and d.dist_no = l.dist_no
)
select *
from reconciliation
where abs(variance) >= 0.01
   or (ledger_signed <> 0 and detail_signed = 0)
   or (ledger_signed = 0 and detail_signed <> 0)
order by abs(variance) desc, WORKORDER_BASE_ID, dist_no, GL_ACCOUNT_ID;
