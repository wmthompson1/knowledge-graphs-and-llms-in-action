# Plan - shipments Core 1 Data Model (Operational)
Note: This is an operational plan but wqe will be coding and testing.
This: Documentation\Schema\Data_Models\Customer_Order\Shipping\About Shipping Core 1-3.md

This effort will be called shipments core 1 but may be shortened to Core 1 or SC1 or C1

1. Make a copy of the three stored procedures that are defective, and build a similar pipeline.
2. The Feed, Table, and Stored Procedure names for the Core 1 feed copy are below.
3. Naming for the Crore 1:
   - Feeds begin with Feed_01_Core_<original;>
   - Table names will have _C1 Appended  <original>_C1
   - Stored Procedures - *01*, *02*, *03* maps to Shipments_Core_Feed_01 - 03 see **2. Feeds





# 1. Shipping Core 1 - 3

For Break-Fix Situations, it is neccessary to trace the problem through using a test feed, rather than
consuming time culling through multiple join layers, e.g. select fields from (select more fields)

There is a base query for shipping, but even the base is cluttered with in-line if-then-else.

To address the sales report query problem, a feed called Shipments_Core_Feed_01 willbe constructed.
   in order to map intermediate tables:

Msg 4701, Level 16, State 1, Procedure sp_Shipments_Core_Feed_01, Line 535 [Batch Start Line 21]
Cannot find the object "Feed_01_Core_Intermediate_complement_OT" because it does not exist or you do not have permissions.

Re: Shipments_Core_Feed_02
---------------------------
9:43:25 AM
Started executing query at  Line 13
Msg 7314, Level 16, State 1, Procedure sp_Shipments_Core_Feed_01, Line 547 [Batch Start Line 13]
The OLE DB provider "MSOLEDBSQL" for linked server "SQL-Bi-1" does not contain the table ""LIVESupplemental"."dbo"."PBI_Customer_Shipments_ARC_C01"". The table either does not exist or the current user does not have permissions on that table.
9:43:25 AM
Total execution time: 00:00:00.073

   TEMP TABLES CAN BE QUICKLY TAGGED WITH <name>_C01

# 2. Feeds - Mapped for Shipments Core 1
   map source                                                                  map Target
 SP_SK_ETL03_CUST_SHIP                                                           Shipments_Core_Feed_01
  SP_SK_ETL02_CUST_SHIP                                                           Shipments_Core_Feed_02
    SP_SK_ETL03_CUST_SHIP                                                           Shipments_Core_Feed_03

# Feeds Mapped for Shipments Core

   map source                                                        map Target
         PBI_Customer_Shipments_complement                               LIVESupplemental.dbo.PBI_Customer_Shipments_complement_C01
                      PBI_Customer_Shipments_complement_OT               Feed_01_Core_Intermediate_complement_OT                                           
 LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT_01            Feed_01_Core_Intermediate_complement_OT_01
   LIVESupplemental.dbo.PBI_Customer_Shipments_new                       LIVESupplemental.dbo.PBI_Customer_Shipments_new_C01
   ignore:
     ignore [SQL-Bi-1].LIVESupplemental.dbo.PBI_Customer_Shipments_ARC        ignore    PBI_Customer_Shipments_ARC_C01

proc2
LIVESupplemental.dbo.PBI_Customer_Shipments01   --->> LIVESupplemental.dbo.PBI_Customer_Shipments01_C1
LIVESupplemental.dbo.PBI_Customer_Shipments01   --->>LIVESupplemental.dbo PBI_Customer_Shipments01_C1       


** proc 01 depends on proc 2 for PBI_Customer_Shipments_complement_OT???

 # Queries Mapped for Shipments Core

   map source                                                                  map Target
                                                                       Shipments_Core

## dependencies not mapped

[SQL-Bi-1].[LIVESupplemental].[dbo].[Plant_Shipment_Forecast] 


## Problems Copying and Renaming Objects For Core 1 Feed
Error
/@Documentation\Schema\Data_Models\Customer_Order\Shipping\sp_Shipments_Core_Feed_01.sql

Msg 4701, Level 16, State 1, Procedure sp_Shipments_Core_Feed_01, Line 535 [Batch Start Line 24]
Cannot find the object "Feed_01_Core_Intermediate_complement_OT" because it does not exist or you do not have permissions.

Steps 
  - Will continue with copying *01*, *02*, *03*  to Shipments_Core_Feed_01 - 03 and tracking dependenciew

  ## Unshipped Qty
  

			, CASE
				WHEN COL.LINE_STATUS = 'C' THEN 0
				WHEN CO.[STATUS] = 'C' THEN 0
				WHEN COL.ORDER_QTY < COL.TOTAL_SHIPPED_QTY THEN 0
				ELSE COL.ORDER_QTY - COL.TOTAL_SHIPPED_QTY
			END AS UNSHIPPEDQTY

