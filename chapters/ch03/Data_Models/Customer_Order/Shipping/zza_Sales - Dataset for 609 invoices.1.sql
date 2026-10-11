-- zza_Sales - Dataset for 609 invoices.sql
-- CMP Shipments
-- pointer server: SQL-BI-1
-- pointer db: LIVESupplemental
-- Forecast: [SQL-Bi-1].[LIVESupplemental].[dbo].[Plant_Shipment_Forecast] PSF WITH (NOLOCK)

SELECT 
   CASE 
   WHEN RL.GL_ACCOUNT_ID = '4310' THEN 'CMP-MFG'
   WHEN RL.GL_ACCOUNT_ID = '4230' THEN 'CMP-FIN' 
   ELSE ''  END AS 'UPDATEBUSSTREAM'  
   ,EOMONTH(INVOICE_DATE) as 'EOM_INVOICED_DATE'
   ,AMOUNT as 'TOTAL INVOICE'
   , 'CMP-Total' AS 'TARGET TOTAL'
FROM   dbo.RECEIVABLE R  
LEFT OUTER JOIN dbo.RECEIVABLE_LINE RL  ON R.INVOICE_ID = RL.INVOICE_ID 
LEFT OUTER JOIN [SQL-Bi-1].[LIVESupplemental].[dbo].[Plant_Shipment_Forecast] PSF  
    ON DATEADD(DD,-(DAY(R.INVOICE_DATE)-1), R.INVOICE_DATE) = PSF.[DATE]  
	 AND PSF.BUSSTREAM = 
        CASE WHEN RL.GL_ACCOUNT_ID = '4310' THEN 'CMP-MFG' 
        WHEN RL.GL_ACCOUNT_ID = '4230' THEN 'CMP-FIN' 
        ELSE ''  END 
LEFT OUTER JOIN [SQL-Bi-1].[LIVESupplemental].[dbo].[Plant_Shipment_Forecast] PSF2  
        ON DATEADD(DD,-(DAY(R.INVOICE_DATE)-1), R.INVOICE_DATE) = PSF2.[DATE]  
				AND PSF2.BUSSTREAM = 'CMP-Total' 
WHERE 
RL.GL_ACCOUNT_ID in ('4230', '4310') 
AND 
RL.AMOUNT <> 0  
AND R.[STATUS] = 'A'  
AND (R.INVOICE_DATE >= '1/1/2021'  AND R.INVOICE_DATE < '12/31/2029') 
AND R.CUSTOMER_ID = 'BOE609' 
union all
Select t.BusStream,EOMONTH(t.Date),t.Target, 'Total' CMP_Total
from [SQL-Bi-1].[LIVESupplemental].[dbo].[Plant_Shipment_Forecast] t 


where BusStream in ('CMP-FIN', 'CMP-MFG')
--ORDER BY 2