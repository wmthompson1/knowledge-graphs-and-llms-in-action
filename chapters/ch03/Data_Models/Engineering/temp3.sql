-- select all work orders for 'boe609' that are in status 'RELEASED' or 'HOLD' and order by due date
SELECT *
FROM dbo.WORK_ORDERS
WHERE PART_ID = 'boe609'
  AND STATUS IN ('RELEASED', 'HOLD')
ORDER BY DUE_DATE;			
																														
