declare @BatchSize int = 1000;                -- rows per auto-generated batch
declare @AutoPopulateBatches bit = 1;          -- set 1 to create batches from @SourceTable when batch_master is empty
declare @SourceTable nvarchar(128) = 'Staging.dbo.my_work_order';
declare @TargetTable nvarchar(128) = 'live.dbo.work_order';
declare @BatchMasterTable nvarchar(128) = 'Staging.dbo.batch_master';
declare @ID_Field NVARCHAR(50) = 'BASE_ID'
declare @Message nvarchar(4000);

select * from Staging.dbo.my_work_order
where flagged = 1;

select flagged, count(*) countof
from [Staging].[dbo].[my_work_order]
where 1=1
group by flagged;


-- posting_candidate flag verification
select * from live.dbo.work_order
where posting_candidate = 'Y';

select posting_candidate, count(*) countof
from live.dbo.work_order
where 1=1
group by posting_candidate;

-- Merge posting_candidate = 'Y' from live.dbo.work_order into Staging.dbo.my_work_order on BASE_ID.
-- Update existing rows to flagged=1; insert live rows that do not yet exist in staging.

merge Staging.dbo.my_work_order as target
using (
    select BASE_ID, max(posting_candidate) as posting_candidate
    from live.dbo.work_order
    where posting_candidate = 'Y'
    group by BASE_ID
) as source
on target.BASE_ID = source.BASE_ID

-- when matched and (target.flagged <> 1 or target.flagged is null) then
--     update set flagged = 1

when not matched by target then
    insert (BASE_ID, flagged)
    values (source.BASE_ID, 1);


