/*
Engineer - Planning Daily Metrics 0716
*/

/*

I need to change the ending point expressed in this query
dateadd(day,4,DESIRED_RLS_DATE)
as 
```sql
CASE WHEN DATEPART(WEEKDAY, x) = 7 THEN DATEADD(DW, 2, x) 
		 WHEN DATEPART(WEEKDAY, x) = 1 THEN DATEADD(DW, 1, x) 
		 ELSE x
	END
```

here in Documentation\Schema\Data_Models\Engineering\Engineer - Planning Daily Metrics 0716.sql

*/



Select
  '02) CMP P/D' note
  , Count(WO.Base_ID) countOf
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id = 'BOE609'
and wo.status = 'f'
AND CASE
		WHEN DATEPART(WEEKDAY, dateadd(day,0,getdate())) = 7 THEN DATEADD(DW, 2, dateadd(day,0,getdate()))
		WHEN DATEPART(WEEKDAY, dateadd(day,0,getdate())) = 1 THEN DATEADD(DW, 1, dateadd(day,0,getdate()))
		ELSE dateadd(day,0,getdate())
	END <= CASE
		WHEN DATEPART(WEEKDAY, dateadd(day,4,DESIRED_RLS_DATE)) = 7 THEN DATEADD(DW, 2, dateadd(day,4,DESIRED_RLS_DATE))
		WHEN DATEPART(WEEKDAY, dateadd(day,4,DESIRED_RLS_DATE)) = 1 THEN DATEADD(DW, 1, dateadd(day,4,DESIRED_RLS_DATE))
		ELSE dateadd(day,4,DESIRED_RLS_DATE)
	END