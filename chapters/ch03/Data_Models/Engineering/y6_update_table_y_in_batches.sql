-- Documentation\Schema\Data_Models\Engineering\x6_update_table_x_in_batches.sql

-- Set-based batch update controlled by a preset batch_master table.
-- Each batch_master row defines a transaction_id range and tracks status
-- (PENDING / RUNNING / COMPLETED / FAILED). The script iterates over pending
-- batches, updates live.dbo.labor_ticket for the matching source rows, and
-- updates batch_master status. Lock waits are capped by LOCK_TIMEOUT so a
-- blocked batch can wait/retry instead of hanging indefinitely.

set nocount on;
set xact_abort off;
set lock_timeout 10000;

-- ---------------------------------------------------------------------------
-- Configurable variables
-- ---------------------------------------------------------------------------
declare @BatchSize int = 1000;                -- rows per auto-generated batch
declare @AutoPopulateBatches bit = 1;          -- set 1 to create batches from @SourceTable when batch_master is empty
declare @SourceTable nvarchar(128) = 'Staging.dbo.my_work_order';
declare @TargetTable nvarchar(128) = 'live.dbo.work_order';
declare @BatchMasterTable nvarchar(128) = 'Staging.dbo.batch_master';
declare @ID_Field NVARCHAR(50) = 'BASE_ID'
declare @Message nvarchar(4000);

-- ---------------------------------------------------------------------------
-- Ensure the batch control table exists.
-- If you already created batch_master with a different schema, comment out
-- this block or adjust the column names to match your table.
-- ---------------------------------------------------------------------------

if object_id(@BatchMasterTable, 'U') is null
begin
    create table Staging.dbo.batch_master
    (
        batch_id             int identity(1,1) not null primary key,
        batch_name           nvarchar(100)     null,
        start_id nvarchar(30)      not null,
        end_id   nvarchar(30)      not null,
        status               nvarchar(20)      not null default 'PENDING'
            constraint CK_batch_master_status check (status in ('PENDING','RUNNING','COMPLETED','FAILED')),
        rows_updated         int               null,
        started_at           datetime          null,
        completed_at         datetime          null,
        error_message        nvarchar(max)     null
    );

    create index IX_batch_master_status_id on Staging.dbo.batch_master(status, batch_id);

    set @Message = concat('Created batch_master control table at ', convert(varchar(19), getdate(), 120), '.');
    raiserror(@Message, 0, 1) with nowait;
end;

-- ---------------------------------------------------------------------------
-- Optional: auto-populate batch_master from the source table in chunks of
-- @BatchSize. This is skipped if batch_master already contains rows.
-- ---------------------------------------------------------------------------
if @AutoPopulateBatches = 1
   and not exists (select 1 from Staging.dbo.batch_master)
begin
    ;with ranked as
    (
        select BASE_ID,
               (row_number() over (order by BASE_ID) - 1) / @BatchSize + 1 as batch_no
        from Staging.dbo.my_work_order
    )
    insert into Staging.dbo.batch_master
        (batch_name, start_id, end_id, status)
    select concat('BATCH_', cast(batch_no as nvarchar(10))),
           min(BASE_ID),
           max(BASE_ID),
           'PENDING'
    from ranked
    -- see below
    group by batch_no
    order by batch_no;

    set @Message = concat('Populated batch_master with ', @@ROWCOUNT, ' batches from ', @SourceTable, '.');
    raiserror(@Message, 0, 1) with nowait;
end;

-- ---------------------------------------------------------------------------
-- Working variables
-- ---------------------------------------------------------------------------
declare @BatchId int;
declare @StartId nvarchar(30);
declare @EndId nvarchar(30);
declare @TotalBatches int;
declare @CompletedBatches int = 0;
declare @FailedBatches int = 0;
declare @UpdatedRows int = 0;
declare @RetryCount int;
declare @MaxRetries int = 12;
declare @RowsAffected int;
declare @Abort bit = 0;
declare @ErrorMessage nvarchar(2048);
declare @start_BatchId int = 11;
declare @end_batchid int = 15;

select @TotalBatches = count(*)
from Staging.dbo.batch_master
where batch_id between @start_BatchId and @end_batchid;

set @Message = concat('Starting batch-controlled posting_candidate update for batches ', @start_BatchId, ' through ', @end_batchid, ' (', @TotalBatches, ' pending) at ', convert(varchar(19), getdate(), 120), '.');
raiserror(@Message, 0, 1) with nowait;

-- ---------------------------------------------------------------------------
-- Main loop: claim next pending batch, update its rows, record status.
-- UPDLOCK + READPAST lets multiple processes safely pick distinct batches.
-- ---------------------------------------------------------------------------
while 1 = 1
begin
    set @BatchId = null;

    select top 1
        @BatchId = batch_id,
        @StartId = start_id,
        @EndId   = end_id
    from Staging.dbo.batch_master with (updlock, readpast)
    where status = 'PENDING'
      and batch_id between @start_BatchId and @end_batchid
    order by batch_id;

    if @BatchId is null
    begin
        set @Message = 'No pending batches remaining.';
        raiserror(@Message, 0, 1) with nowait;
        break;
    end;

    update Staging.dbo.batch_master
    set status = 'RUNNING',
        started_at = getdate(),
        error_message = null
    where batch_id = @BatchId;

    set @RetryCount = 0;

    while 1 = 1
    begin
        begin try
            begin transaction;

            update t
            set posting_candidate = 'Y'
            from live.dbo.work_order t
            join staging.dbo.my_work_order s
                on s.base_id = t.base_id
            where s.base_id between @StartId and @EndId
              and t.posting_candidate <> 'Y';

            set @RowsAffected = @@rowcount;

            commit transaction;

            set @UpdatedRows += @RowsAffected;

            -- flag in my_work_order as processed
            update staging.dbo.my_work_order
            set flagged = 1
            where base_id between @StartId and @EndId;

            update staging.dbo.batch_master
            set status = 'COMPLETED',
                completed_at = getdate(),
                rows_updated = @RowsAffected
            where batch_id = @BatchId;

            set @CompletedBatches += 1;

            break;
        end try
        begin catch
            if xact_state() <> 0
            begin
                rollback transaction;
            end;

            if error_number() in (1205, 1222) and @RetryCount < @MaxRetries
            begin
                set @RetryCount += 1;
                set @Message = concat('Blocked/deadlocked on batch ', @BatchId, '; retry ', @RetryCount, ' of ', @MaxRetries, ' after 5 seconds. Error ', error_number(), ': ', error_message());
                raiserror(@Message, 0, 1) with nowait;
                waitfor delay '00:00:05';
            end
            else
            begin
                set @FailedBatches += 1;
                set @ErrorMessage = concat('Failed batch ', @BatchId, '. Error ', error_number(), ', severity ', error_severity(), ', state ', error_state(), ', line ', error_line(), ': ', error_message());
                raiserror(@ErrorMessage, 0, 1) with nowait;

                update staging.dbo.batch_master
                set status = 'FAILED',
                    completed_at = getdate(),
                    error_message = @ErrorMessage
                where batch_id = @BatchId;

                set @Abort = 1;
                break;
            end;
        end catch;
    end;

    if @Abort = 1
    begin
        break;
    end;

    if @CompletedBatches % 5 = 0 or @CompletedBatches = @TotalBatches
    begin
        set @Message = concat('Progress: completed ', @CompletedBatches, ' of ', @TotalBatches, ' batches; updated rows=', @UpdatedRows, '; failed batches=', @FailedBatches, '; current batch=', @BatchId, '.');
        raiserror(@Message, 0, 1) with nowait;
    end;
end;

set lock_timeout -1;

set @Message = concat('Completed batch-controlled update at ', convert(varchar(19), getdate(), 120), '. Total batches=', @TotalBatches, '; completed=', @CompletedBatches, '; failed=', @FailedBatches, '; updated rows=', @UpdatedRows, '.');
raiserror(@Message, 0, 1) with nowait;

if @Abort = 1
begin
    throw 50001, @ErrorMessage, 1;
end;


/**

update w
set 
   posting_candidate = 'Y'
from live.[dbo].[WORK_ORDER] w
join [Staging].[dbo].[my_table_updates] s
on w.BASE_ID = s.BASE_ID
**/