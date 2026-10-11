
-- Row-by-row update with progress output, transaction handling, and blocker retry wait.
-- Lock waits are capped by LOCK_TIMEOUT so a blocked row can wait/retry instead of hanging indefinitely.

set nocount on;
set xact_abort off;
set lock_timeout 10000;

declare @ID nvarchar(30);
declare @TotalRows int;
declare @ProcessedRows int = 0;
declare @UpdatedRows int = 0;
declare @SkippedRows int = 0;
declare @FailedRows int = 0;
declare @RetryCount int;
declare @MaxRetries int = 12;
declare @RowsAffected int;
declare @Message nvarchar(4000);
declare @Abort bit = 0;
declare @ErrorMessage nvarchar(2048);
declare @tableX nvarchar(128) = '[live].[dbo].[LABOR_TICKET]';

select @TotalRows = count(*)
--from [Staging].[dbo].[my_table_updates];
from [Staging].[dbo].[My_LABOR_TICKET];

-- table x My_LABOR_TICKET (staging table for updates)
-- -->
-- live.dbo.labor_ticket

set @Message = concat('Starting x posting_candidate update for ', @TotalRows, ' staged ID rows at ', convert(varchar(19), getdate(), 120), '.');
raiserror(@Message, 0, 1) with nowait;

declare update_cursor cursor local fast_forward for
select X.[transaction_id]
-- from [Staging].[dbo].[my_table_updates] x
from [Staging].[dbo].[My_LABOR_TICKET] x
--JOIN live.[dbo].[WORK_ORDER] w
join live.[dbo].[labor_ticket] w
-- on x.base_id = w.base_id
on x.transaction_id = w.transaction_id
WHERE w.posting_candidate <> 'Y'
-- order by base_id
order by X.[transaction_id];



open update_cursor;
fetch next from update_cursor into @ID;

while @@FETCH_STATUS = 0
begin
    set @RetryCount = 0;

    while 1 = 1
    begin
        begin try
            begin transaction;

            update live.[dbo].[labor_ticket]
            set posting_candidate = 'Y'
            where transaction_id = @ID;

            set @RowsAffected = @@ROWCOUNT;

            commit transaction;

            set @ProcessedRows += 1;
            set @UpdatedRows += @RowsAffected;

            if @RowsAffected = 0
            begin
                set @SkippedRows += 1;
                set @Message = concat('No x row matched id ', @ID, '. Processed ', @ProcessedRows, ' of ', @TotalRows, '.');
                raiserror(@Message, 0, 1) with nowait;
            end;

            if @ProcessedRows % 200 = 0 or @ProcessedRows = @TotalRows
            begin
                set @Message = concat('Progress: processed ', @ProcessedRows, ' of ', @TotalRows,'; updated rows=', @UpdatedRows, '; no-match rows=', @SkippedRows, '; failed rows=', @FailedRows, '; current transaction_id=', @ID, '.');
                raiserror(@Message, 0, 1) with nowait;
            end;

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
                set @Message = concat('Blocked/deadlocked on id ', @ID, '; retry ', @RetryCount, ' of ', @MaxRetries, ' after 5 seconds. Error ', error_number(), ': ', error_message());
                raiserror(@Message, 0, 1) with nowait;
                waitfor delay '00:00:05';
            end
            else
            begin
                set @FailedRows += 1;
                set @ErrorMessage = concat('Failed id ', @ID, '. Error ', error_number(), ', severity ', error_severity(), ', state ', error_state(), ', line ', error_line(), ': ', error_message());
                raiserror(@ErrorMessage, 0, 1) with nowait;
                set @Abort = 1;
                break;
            end;
        end catch;
    end;

    if @Abort = 1
    begin
        break;
    end;

    fetch next from update_cursor into @ID;
end;

close update_cursor;
deallocate update_cursor;

set lock_timeout -1;

set @Message = concat('Completed x update at ', convert(varchar(19), getdate(), 120), '. Processed=', @ProcessedRows, '; updated rows=', @UpdatedRows, '; no-match rows=', @SkippedRows, '; failed rows=', @FailedRows, '.');
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