 /**
 
 PROGRAM_ID,ID,DATA_TYPE,DATA_TYPE_DESC,LABEL
VMPRTMNT,UDF-0000038,3,NUMBER_VAL,Width
VMPRTMNT,UDF-0000084,1005,STRING_VAL,Certifications Needed
VMPRTMNT,UDF-0000091,1,BOOL_VAL,Limited Scope
VMPRTMNT,UDF-0000103,1,BOOL_VAL,Frozen Process
VMPRTMNT,UDF-0000039,3,NUMBER_VAL,Thickness
VMPRTMNT,UDF-0000036,5,STRING_VAL,Alloy
VMPRTMNT,UDF-00115,1,BOOL_VAL,Supplier Controlled Drawing
VMPRTMNT,UDF-0000092,5,STRING_VAL,Primer
VMPRTMNT,UDF-0000040,1,BOOL_VAL,ITAR Controlled (Yes if checked)
VMPRTMNT,UDF-0000026,3,NUMBER_VAL,Surface Area (sq in)
VMPRTMNT,UDF-0000082,1005,STRING_VAL,Controlled
VMPRTMNT,UDF-0000037,3,NUMBER_VAL,Length
VMPRTMNT,UDF-0000035,1005,STRING_VAL,Material Type
VMPRTMNT,UDF-0000085,5,STRING_VAL,Used on Part ID
VMPRTMNT,UDF-0000099,5,STRING_VAL,Topcoat
VMPRTMNT,UDF-0000101,5,STRING_VAL,QC Notes:

 
 **/
 
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
  where program_id = 'VMMFGWIN_WO'
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
  where program_id = 'VMMFGWIN_WO' -- -- 'vmprtmnt'
  --and document_id is not null
  group by     
	[program_id]
	,[id]
	,[data_type]
)
-- would youi correct the grain of the join? I think we need to join on program_id, id and document_id to get the correct label for each document_id
-- but I need to join the header without cartesian product to get the data type and label for each id. I think we can do that by joining on program_id, id and document_id in the detail table and just program_id and id in the header table. Let me know if that makes sense.
, header_detail as (

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
  where program_id = 'VMMFGWIN_WO'
  --and id  = 'udf-0000026'
  and document_id is null
  group by     
    [program_id]
    ,[id]
    ,[data_type]
)
select * from header_detail;


     SELECT
         PROGRAM_ID

     FROM USER_DEF_FIELDS
     group by PROGRAM_ID;
 
--  CTE_USER_DEF_FIELDS_VMPRTMNT AS (
--      SELECT
--          DOCUMENT_ID,
--          MAX(CASE WHEN ID = 'UDF-0000026' THEN STRING_VAL ELSE NULL END) AS [Surface Area],
--          MAX(CASE WHEN ID = {ID} THEN {DATA_TYPE_DESC} ELSE NULL END) AS {LABEL},


--      FROM USER_DEF_FIELDS
--      WHERE PROGRAM_ID = '{PROGRAM_ID}'
--      GROUP BY DOCUMENT_ID

--  VMMFGWIN_WO  

    --  SELECT
    --      DOCUMENT_ID,
    --      VMMFGWIN_WO.[UDF-0000026] AS [Surface Area],
    --      VMMFGWIN_WO.[UDF-0000035] AS [Material Type],
    --      VMMFGWIN_WO.[UDF-0000036] AS [Alloy],          
    --      VMMFGWIN_WO.[UDF-0000037] AS [Length],
    --      VMMFGWIN_WO.[UDF-0000038] AS [Width],
    --      VMMFGWIN_WO.[UDF-0000039] AS [Thickness],
    --      VMMFGWIN_WO.[UDF-0000040] AS [ITAR Controlled (Yes if checked)],
    --      VMMFGWIN_WO.[UDF-0000082] AS [Controlled],
    --      VMMFGWIN_WO.[UDF-0000084] AS [Certifications Needed],
    --      VMMFGWIN_WO.[UDF-0000085] AS [Used on Part ID],
    --      VMMFGWIN_WO.[UDF-0000091] AS [Limited Scope],
    --      VMMFGWIN_WO.[UDF-0000092] AS [Primer],
    --      VMMFGWIN_WO.[UDF-0000099] AS [Topcoat],
    --      VMMFGWIN_WO.[UDF-0000101] AS [QC Notes:],
    --      VMMFGWIN_WO.[UDF-0000103] AS [Frozen Process]



    --  FROM USER_DEF_FIELDS VMMFGWIN_WO
    --  WHERE PROGRAM_ID = 'VMMFGWIN_WO';

