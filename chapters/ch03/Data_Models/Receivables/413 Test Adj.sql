SELECT TOP (10000)
       CUST_ORDER_ID,
       CUSTOMER_ID,
       BUS_STREAM,
       CO_DESIRED_SHIP_DATE,
       ADJUSTED_DUE_DATE,
       FILTER_DATE
FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT
WHERE ADJUSTED_DUE_DATE IS NULL;