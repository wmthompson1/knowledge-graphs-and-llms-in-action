--- williamt 9/3
--  per #2431
SELECT
    COUNT(DISTINCT CASE
        WHEN WO.STATUS = 'R'
        THEN WO.Base_ID
    END) AS [Current WIP],
 
    COUNT(DISTINCT CASE
        WHEN WO.STATUS = 'R'
         AND WO.DESIRED_WANT_DATE < GETDATE()
        THEN WO.Base_ID
    END) AS [Current Past Due],
 
    COUNT(DISTINCT CASE
        WHEN CAST(S.SHIPPED_DATE AS date) =
             CAST(DATEADD(day, -1, GETDATE()) AS date)
        THEN S.PACKLIST_ID
    END) AS [Shipped Yesterday]
 
FROM Customer AS C
LEFT JOIN Customer_order AS CO
    ON CO.Customer_ID = C.ID
LEFT JOIN CUST_ORDER_LINE AS COL
    ON COL.Cust_Order_ID = CO.ID
LEFT JOIN Demand_Supply_link AS DSL
    ON DSL.Demand_Base_ID = COL.Cust_Order_ID
   AND DSL.Demand_Seq_No = COL.Line_no
LEFT JOIN WORK_ORDER AS WO
    ON WO.Base_ID = DSL.Supply_Base_ID
   AND WO.Lot_ID = DSL.Supply_Lot_ID
   AND WO.Split_ID = DSL.Supply_Split_ID
   AND WO.Sub_ID = DSL.Supply_Sub_ID
LEFT JOIN Shipper_line AS SL
    ON SL.CUST_ORDER_ID = COL.CUST_ORDER_ID
   AND SL.CUST_ORDER_LINE_NO = COL.LINE_NO
LEFT JOIN Shipper AS S
    ON S.PACKLIST_ID = SL.PACKLIST_ID
WHERE 1=1 
and CO.CUSTOMER_ID IN (@Customer);

;