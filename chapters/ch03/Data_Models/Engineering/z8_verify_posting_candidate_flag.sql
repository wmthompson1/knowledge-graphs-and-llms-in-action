-- ---------------------------------------------------------------------------
-- Configurable variables
-- ---------------------------------------------------------------------------
declare @BatchSize int = 1000;                -- rows per auto-generated batch
declare @AutoPopulateBatches bit = 1;          -- set 1 to create batches from @SourceTable when batch_master is empty
declare @SourceTable nvarchar(128) = 'Staging.dbo.my_labor_ticket';
declare @TargetTable nvarchar(128) = 'live.dbo.labor_ticket';
declare @BatchMasterTable nvarchar(128) = 'Staging.dbo.batch_master_labor_ticket';
declare @ID_Field NVARCHAR(50) = 'Transaction_ID'


select * from Staging.dbo.my_labor_ticket
where flagged = 1;

select flagged, count(*) countof
from [Staging].[dbo].[my_labor_ticket]
where 1=1
group by flagged;


-- posting_candidate flag verification
select * from live.dbo.labor_ticket
where posting_candidate = 'Y';

-- ------------------------------
--  Assess the batch master
-- ------------------------------

select posting_candidate, count(*) countof
from live.dbo.labor_ticket
where 1=1
group by posting_candidate;

-- -------------------------------
-- Assess the items in staging
-- -------------------------------
-- Q: What does the flagged field indicate in staging?
-- A: The flagged field indicates whether a record in staging has been identified as a posting candidate based on the live table.

select flagged, count(*) countof
from Staging.dbo.my_labor_ticket
group by flagged;

-- ------------------------------
--  Assess the batch master
-- ------------------------------
select * 
 from Staging.dbo.batch_master_labor_ticket;

-- Merge posting_candidate = 'Y' from live.dbo.labor_ticket into Staging.dbo.my_labor_ticket on Transaction_ID.
-- Update existing rows to flagged=1; insert live rows that do not yet exist in staging.

/**

merge Staging.dbo.my_labor_ticket as target
using (
    select Transaction_ID, max(posting_candidate) as posting_candidate
    from live.dbo.labor_ticket
    where posting_candidate = 'Y'
    group by Transaction_ID
) as source
on target.Transaction_ID = source.Transaction_ID

when matched and (target.flagged <> 1 or target.flagged is null) then
    update set flagged = 1

when not matched by target then
    insert (Transaction_ID, flagged)
    values (source.Transaction_ID, 1);


**/




merge Staging.dbo.my_labor_ticket as target
using (
    select Transaction_ID, max(posting_candidate) as posting_candidate
    ,case when posting_candidate = 'Y' then 1 else 0 end as flagged
    from live.dbo.labor_ticket t
    where 1=1
    and [CREATE_DATE] between '1/1/2026' and '6/30/2026'
    -- andposting_candidate = 'Y'
    and transaction_id not in (select Transaction_ID from Staging.dbo.my_labor_ticket)
    group by Transaction_ID,posting_candidate
) as source
on target.Transaction_ID = source.Transaction_ID

-- when matched and (target.flagged <> 1 or target.flagged is null) then
--     update set flagged = 0

when not matched by target then
    insert (Transaction_ID, flagged)
    values (source.Transaction_ID, flagged);

/** 
update Staging.dbo.my_labor_ticket 
    set flagged = 1

    
**/


