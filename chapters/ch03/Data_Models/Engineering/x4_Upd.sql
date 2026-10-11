
-- would you create a cursor that updates row by row as follows? place in x4_Upd.sql
/**Yes, I can help you create a cursor that updates rows one by one. Below is an example of how you can implement a cursor in your SQL script to update the `posting_candidate` field row by row based on the join condition with the staging table.

1. check the trigger list
2. request row-by-row 

**/

declare @BASE_ID nvarchar(30);

declare update_cursor cursor local fast_forward for
select [BASE_ID]
from [Staging].[dbo].[my_table_updates];

open update_cursor;
fetch next from update_cursor into @BASE_ID;

while @@FETCH_STATUS = 0
begin
    update live.[dbo].[WORK_ORDER]
    set posting_candidate = 'Y'
    where BASE_ID = @BASE_ID;

    fetch next from update_cursor into @BASE_ID;
end

close update_cursor;
deallocate update_cursor;

/**

update w
set 
   posting_candidate = 'Y'
from live.[dbo].[WORK_ORDER] w
join [Staging].[dbo].[my_table_updates] s
on w.BASE_ID = s.BASE_ID
**/