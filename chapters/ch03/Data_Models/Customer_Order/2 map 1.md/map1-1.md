## Report Header and Values
1.

| Cust ID  | Status   | CO/Line  | Cust/PO Line | Part ID  | Part/MBU  | Description   | Buyer ID     | Qty Due   | RTQTY DUE   |
|----------|----------|----------|--------------|----------|-----------|---------------|--------------|-----------|-------------|
| [CUSTOM] | [STATUS] | [CO_LINE]| [PO_LINE]    | [PART_ID]| [PART_MBU]| [DESCRIPTION] | [BUYER_USER] | [QTY_DUE] | [RTQTY_DUE] |

** Note 1: Status = In Stock if ATP is positive

   Note 5: RTQTY_DUE Running Total By Order: COL.ORDER_QTY - COL.TOTAL_SHIPPED_QTY

2.

| Ship Date (ASN) | Prom Del   | Prom Ship   | Due Var   | QOH      | WO Due   | Due Var WO   | Prod Status   | UNIT PRICE   |
|------------------|------------|-------------|-----------|----------|----------|--------------|---------------|--------------|
| [DESIRED_SHIP]   | [PROM_DEL] | [PROM_SHIP] | [DUE_VAR] | [PROJ_QT]| [WO_DUE] | [DUE_VAR_WO] | [PROD_STATUS] | [UNIT_PRICE] |

** Note 2: QOH is projected. 
   
   Note 4:  DUE_VAR_WO = # days WO_DUE-DESIRED_SHIP_DATE -- WO_DUE  =  WODS_DESIRED_WANT_DATE; yellow if < -14 

   Note 6:  DUE_VAR = # of days = promise - desired_ship

   Note 13: PROD_STATUS; if In Stock: p.QTY_AVAILABLE_ISS - QD.RTQTY_DUE  >= 0 Else Work Order Details

3.
| UNIT PRICE   | Total $       | Ship Note (U6) | FLT/EXP (U10) | Visual LT         | Cust ROLT   | Act. LT           | Expires       | ADDR NO    | NAME    |
|--------------|---------------|----------------|---------------|-------------------|-------------|-------------------|---------------|------------|---------|
| [UNIT_PRICE] | [TOTAL_DOLLAR] | [USER_6]       | [USER_10]     | [PLANNING_LEAD]  | [CUST_ROLT] | [M_DAY_LEADTIME]  | [DRAWING_ID]  | [ADDR_NO]  | [NAME]  |

** Note 3: M_DAY_LEADTIME - consecutive numbering system for operating days on a production calendar
 
   Note 7: TOTAL_DOLLAR = (COL.ORDER_QTY - COL.TOTAL_SHIPPED_QTY) * COL.UNIT_PRICE

   Note 8: CUST_ROLT = In manufacturing, ROLT stands for Requested Order Lead Time. It is the specific amount of time, requested by the customer, between the date an order is placed and the date they expect the delivery.

   Notes 9 - 12
        COL.USER_6                                       Ship Note(U6) 
        COL.USER_10                                      FLT/EXP(U10) 
        P.PLANNING_LEADTIME,                             Visual LT 
        P.USER_10 AS CUST_ROLT,                          CUST ROLT

4.
| SHIPTO  | ADDR 1   | ADDR_2  | CITY  | STATE  |
|---------|----------|---------|-------|--------|
| [SHIPTO]| [ADDR_1] | [ADDR_2]| [CITY]| [STATE]|
