--zzbX1.sql
SELECT sum(SHIPPED_AMOUNT) x, bus_stream 
FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement 
WHERE FILTER_DATE >= '2025-01-01'
group by bus_stream