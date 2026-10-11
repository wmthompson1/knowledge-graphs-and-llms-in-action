BOE_BILLING_FINISH




## Shipments Core Feed 1

```sql
SELECT * FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement 
WHERE FILTER_DATE >= '2025-01-01'
```


## BOE Billing Core Feed 2

```sql
Select top 10 
   PackSlip, [unit price], [extended dollars], [expedite dollars], [special fees], [setup hours], [run hours], [expedite hours], [pack slips / date], [invoice id], [comments]
FROM LI
```


