-- user_defined_fields_pivot
with header as
(
select 
     [program_id]
    ,[id]
   	,case 
	when [data_type] = 5 then 'string_val'
	when [data_type] = 3 then 'number_val'
	when [data_type] = 1 then 'bool_val'
	   else 'string_val' -- list
	end [data_type_desc]
	,[data_type]
	  ,max(label) label
  from [live].[dbo].[user_def_fields]
  where program_id = 'vmprtmnt'
  --and id  = 'udf-0000026'
  and document_id is null
  group by     
	[program_id]
	,[id]
	,[data_type]
), detail as (
select 
       [program_id]
      ,[id]
	  ,max(label) label
	  ,max([document_id]) [document_id]
      ,max([string_val]) [string_val]
      ,max([number_val]) [number_val]
      ,max([bool_val]) [bool_val]
      ,max([date_val]) [date_val]
  from [live].[dbo].[user_def_fields]
  where program_id = 'vmprtmnt'
  and document_id is not null
  group by     
	[program_id]
	,[id]
	,[data_type]
)
select 
     d.[program_id]
    ,d.[id]
    ,[data_type]
	,[data_type_desc]
	,h.[label]
from detail d
join header h
on d.id = h.id