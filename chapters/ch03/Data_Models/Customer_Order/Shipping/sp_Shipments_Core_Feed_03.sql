USE [LIVE]
GO

/****** Object:  StoredProcedure [dbo].[SP_SK_ETL03_CUST_SHIP]    Script Date: 7/9/2026 10:10:26 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/* =============================================
-- Author:		JC
-- Create date: 03/25/2025
-- Description:	Data set for PBI_Customer_Shipments01
*/

--CREATE PROCEDURE [dbo].SP_SK_ETL03_CUST_SHIP AS
alter PROCEDURE [dbo].sp_Shipments_Core_Feed_03
AS

SET NOCOUNT off;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW


-- # Feeds Mapped for Shipments Core

--    map source                                                        map Target
--          PBI_Customer_Shipments_complement                               LIVESupplemental.dbo.PBI_Customer_Shipments_complement_C01
--                       PBI_Customer_Shipments_complement_OT               Feed_01_Core_Intermediate_complement_OT                                           
--  LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT_01            Feed_01_Core_Intermediate_complement_OT_01
--    LIVESupplemental.dbo.PBI_Customer_Shipments_new                       LIVESupplemental.dbo.PBI_Customer_Shipments_new_C01
--    ignore:
--      ignore [SQL-Bi-1].LIVESupplemental.dbo.PBI_Customer_Shipments_ARC        ignore    PBI_Customer_Shipments_ARC_C01

-- proc2
-- LIVESupplemental.dbo.PBI_Customer_Shipments01                           LIVESupplemental.dbo.PBI_Customer_Shipments01_C1
-- LIVESupplemental.dbo.PBI_Customer_Shipments01                           LIVESupplemental.dbo.PBI_Customer_Shipments01_C1
-- ~22 from 01

/******************************************************************************************************/
/****   Take data from PBI_Customer_Shipments_complement and create data for On Time Delivery   *******/
/******************************************************************************************************/

-- ----------------------------------
--  CORE 1
--  ~22
  -- INTO LIVESupplemental.dbo.PBI_Customer_Shipments_ARC_C01
-- note: 
 ---  The previous reporting analyst inadvertently factored out a field being used to filter
 --   the set.
-- ----------------------------------

-- --m core 1 
-- drop table LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT


-- SELECT
--  *
--   INTO LIVESupplemental.dbo.PBI_Customer_Shipments_ARC_C01
-- FROM LIVESupplemental.dbo.PBI_Customer_Shipments_ARC 



--  SELECT
--  *
--  INTO LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT
--  FROM
--  LIVESupplemental.dbo.PBI_Customer_Shipments_complement_C01

--  -- 2
--  SELECT A.*, CL.USER_6, 'LIVE' BASE_TABLE
--   INTO LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT
-- FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_C01 A WITH (NOLOCK)
-- LEFT JOIN LIVE.dbo.CUST_ORDER_LINE CL WITH (NOLOCK) ON A.CUST_ORDER_ID = CL.CUST_ORDER_ID 
-- 	AND A.COL_LINE_NO = CL.LINE_NO
-- WHERE A.FILTER_DATE >= '2024-12-24' --and a.CUST_ORDER_ID = '498033' order by a.COL_LINE_NO

--  select *
--  FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_C01 A WITH (NOLOCK)

-- select * from
--  LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT
-- union all
--  select * from LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT
--  union all
--  select * FROM [SQL-Bi-1].LIVESupplemental.dbo.PBI_Customer_Shipments_ARC_C01 A WITH (NOLOCK)
-- ~22 from 01 /





/*	Exclude all customer orders lines that have CBO in the user defined 6. (Update requested by Monica 24-Apr-2025) 	*/
-- DELETE FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT
-- WHERE 1=1  
   -- williamt 7/31/2026 expedite
  -- COL_UDF6 = 'CBO' AND BUS_STREAM = 'MFG'
DELETE FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT
WHERE ORDER_STATUS = 'CANCELLED'


/************************************************************************************************ 
				Fix ADJUSTED_DUE_DATE for BUS_STREAM  'CMP-FIN' OR 'CMP-MFG'
*************************************************************************************************/

/***	Fix ADJUSTED_DUE_DATE for BUS_STREAM = 'CMP-FIN' take DESIRED_RLS_DATE + 10 Day 
	from WORK ORDER. If the Customer Order (CO) Desired Date is later than the Adjusted Due Date, 
	use the later of the two as the final due date (Update requested by Monica 24-Apr-2025)  ***/

UPDATE A SET A.ADJUSTED_DUE_DATE =
	CASE 
		WHEN a.CO_DESIRED_SHIP_DATE IS NULL THEN a.ADJUSTED_DUE_DATE
		WHEN a.CO_DESIRED_SHIP_DATE IS NOT NULL AND a.ADJUSTED_DUE_DATE >= a.CO_DESIRED_SHIP_DATE THEN a.ADJUSTED_DUE_DATE
		WHEN a.CO_DESIRED_SHIP_DATE IS NOT NULL AND a.ADJUSTED_DUE_DATE < a.CO_DESIRED_SHIP_DATE THEN a.CO_DESIRED_SHIP_DATE
	END
-- select * 
FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT A WITH (NOLOCK)
--INNER JOIN LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
WHERE A.BUS_STREAM = 'CMP-FIN' OR A.BUS_STREAM = 'CMP-MFG' 



/************************************************************************************************ 
				Fix ADJUSTED_DUE_DATE for BUS_STREAM  'FIN' OR 'MFG'
*************************************************************************************************/

/* Fix ADJUSTED_DUE_DATE for BUS_STREAM = 'MFG' take Customer Order Line – Promise Delivery Date
	If the promise delivery date is blank on the customer order line use the customer order header 
	promise delivery date. (Update requested by Monica 24-Apr-2025)	*/
UPDATE A SET A.ADJUSTED_DUE_DATE = 
		IIF(CL.PROMISE_DATE IS NULL, C.DESIRED_SHIP_DATE, CL.PROMISE_DATE)
FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT A WITH (NOLOCK)
INNER JOIN LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
INNER JOIN CUST_ORDER_LINE CL WITH (NOLOCK) ON A.CUST_ORDER_ID = CL.CUST_ORDER_ID and a.COL_LINE_NO = CL.LINE_NO
INNER JOIN CUSTOMER_ORDER C WITH (NOLOCK) ON A.CUST_ORDER_ID = C.ID
WHERE A.CO_DESIRED_SHIP_DATE is not null and a.RowID = b.RowID AND A.BUS_STREAM = 'MFG'
  -- break-ix 7/31/2026 
	-- AND A.BASE_TABLE = 'LIVE'

-- UPDATE A SET A.ADJUSTED_DUE_DATE = 
-- 		IIF(CL.PROMISE_DATE IS NULL, C.DESIRED_SHIP_DATE, CL.PROMISE_DATE)
-- FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT A WITH (NOLOCK)
-- INNER JOIN LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
-- INNER JOIN [SQL-Lab-2].[LIVEARC].dbo.CUST_ORDER_LINE CL WITH (NOLOCK) ON A.CUST_ORDER_ID = CL.CUST_ORDER_ID and a.COL_LINE_NO = CL.LINE_NO
-- INNER JOIN [SQL-Lab-2].[LIVEARC].dbo.CUSTOMER_ORDER C WITH (NOLOCK) ON A.CUST_ORDER_ID = C.ID
-- WHERE A.CO_DESIRED_SHIP_DATE is not null and a.RowID = b.RowID AND A.BUS_STREAM = 'MFG'
-- 	AND A.BASE_TABLE = 'LIVEARC'

/*	Fix ADJUSTED_DUE_DATE for BUS_STREAM = 'FIN' take Desired Ship Date from CO Header.
	For customers AERMAN and AMTRIB, add 1 day for transportation (Update requested by Monica 24-Apr-2025)  */
UPDATE A SET 
	A.ADJUSTED_DUE_DATE = 
	CASE WHEN A.CUSTOMER_ID = 'AERMAN' OR A.CUSTOMER_ID = 'AMTRIB' 
		THEN DATEADD(DAY, 1, C.DESIRED_SHIP_DATE)
	ELSE C.DESIRED_SHIP_DATE
	END
FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT A WITH (NOLOCK)
INNER JOIN LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
INNER JOIN [SQL-Lab-1].[LIVE].dbo.CUSTOMER_ORDER C WITH (NOLOCK) ON A.CUST_ORDER_ID = C.ID
WHERE A.CO_DESIRED_SHIP_DATE is not null and a.RowID = b.RowID AND A.BUS_STREAM = 'FIN'
   -- williamT
	-- AND A.BASE_TABLE = 'LIVE'

-- UPDATE A SET 
-- 	A.ADJUSTED_DUE_DATE = 
-- 	CASE WHEN A.CUSTOMER_ID = 'AERMAN' OR A.CUSTOMER_ID = 'AMTRIB' 
-- 		THEN DATEADD(DAY, 1, C.DESIRED_SHIP_DATE)
-- 	ELSE C.DESIRED_SHIP_DATE
-- 	END
-- FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT A WITH (NOLOCK)
-- INNER JOIN LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
-- INNER JOIN [SQL-Lab-2].[LIVEARC].dbo.CUSTOMER_ORDER C WITH (NOLOCK) ON A.CUST_ORDER_ID = C.ID
-- WHERE A.CO_DESIRED_SHIP_DATE is not null and a.RowID = b.RowID AND A.BUS_STREAM = 'FIN'
-- 	AND A.BASE_TABLE = 'LIVEARC'


/*	Fix ADJUSTED_DUE_DATE for BUS_STREAM = 'FIN_MFG' take Desired Ship Date from CO Header 
	(This category is being phased out.) (Update requested by Monica 24-Apr-2025) */
UPDATE A SET A.ADJUSTED_DUE_DATE = coalesce(C.DESIRED_SHIP_DATE, A.SHIPPED_DATE, A.INVOICE_DATE)
FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT A WITH (NOLOCK)
INNER JOIN LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
INNER JOIN CUSTOMER_ORDER C WITH (NOLOCK) ON A.CUST_ORDER_ID = C.ID
WHERE A.CO_DESIRED_SHIP_DATE is not null and a.RowID = b.RowID AND A.BUS_STREAM = 'FIN_MFG'
   -- break fix williamt
	--AND A.BASE_TABLE = 'LIVE'

-- UPDATE A SET A.ADJUSTED_DUE_DATE = C.DESIRED_SHIP_DATE
-- FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT A WITH (NOLOCK)
-- INNER JOIN LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
-- INNER JOIN [SQL-Lab-2].[LIVEARC].dbo.CUSTOMER_ORDER C WITH (NOLOCK) ON A.CUST_ORDER_ID = C.ID
-- WHERE A.CO_DESIRED_SHIP_DATE is not null and a.RowID = b.RowID AND A.BUS_STREAM = 'FIN_MFG'
-- 	AND A.BASE_TABLE = 'LIVEARC'


	/**********************************************************************************/
	/**********************************************************************************/

	DELETE FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT
	WHERE TOTAL_SHIPPED_QTY = 0 
	AND ADJUSTED_DUE_DATE >= DATEADD(DAY, 1, CAST(GETDATE() AS DATE))



	/**********************************************************************************/
	/**********************************************************************************/
/************************************************************************************************ 
						Fix OnTime and Late after Fix ADJUSTED_DUE_DATE
*************************************************************************************************/
-- UPDATE A SET A.ON_TIME1 = IIF(A.[FILTER_DATE] <= A.ADJUSTED_DUE_DATE, 1, 0),
-- 			A.LATE1 =  IIF(A.[FILTER_DATE] <= A.ADJUSTED_DUE_DATE, 0, 1)
-- FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT A WITH (NOLOCK)
-- INNER JOIN LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
-- WHERE A.[ON TIME] is not null and a.RowID = b.RowID 
-- ~22 WILLIAMT 8/5
UPDATE A
SET
    A.ON_TIME1 = IIF(A.[FILTER_DATE] <= A.ADJUSTED_DUE_DATE, 1, 0),
    A.LATE1    = IIF(A.[FILTER_DATE] <= A.ADJUSTED_DUE_DATE, 0, 1)
FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT A
WHERE 1=1  -- A.[ON TIME] IS NOT NULL;

/**
SELECT 
    ON_TIME1 = IIF(A.[FILTER_DATE] <= A.ADJUSTED_DUE_DATE, 1, 0),
    LATE1    = IIF(A.[FILTER_DATE] <= A.ADJUSTED_DUE_DATE, 0, 1)
FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT A
WHERE 1=1  -- A.[ON TIME] IS NOT NULL;

**/

	/**********************************************************************************/
	/**********************************************************************************/
/************************************************************************************************ 
						Insert to final table
*************************************************************************************************/
-- drop table LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT_01

/**
select * into LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT_01
from LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT
**/

TRUNCATE TABLE  LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT_01

INSERT INTO LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT_01
(
[CTE]
      ,[CUSTOMER_ID]
      ,[CUST_ORDER_ID]
      ,[COL_LINE_NO]
      ,[ORDER_DATE]
      ,[CREATE_DATE]
      ,[DESIRED_SHIP_DATE]
      ,[FILTER_CASE]
      ,[FILTER_DATE]
      ,[CO_STATUS]
      ,[UPDATE_USING_MISC_REF]
      ,[SERVICE_CHARGE_ID]
      ,[LINE_TYPE]
      ,[LINE_ITEM]
      ,[CHARGE_TYPE]
      ,[CUST_PART_DESC]
      ,[COL_PARTID]
      ,[P2ID]
      ,[PART_ID]
      ,[DESCRIPTION]
      ,[PART_PROD_CODE]
      ,[PART_COMM_CODE]
      ,[PLANNER_USER_ID]
      ,[BUYER_USER_ID]
      ,[REASONING]
      ,[SHIP_SHORT]
      ,[ORDER_QTY]
      ,[TOTAL_SHIPPED_QTY]
      ,[REMQTY]
      ,[UNSHIPPEDQTY]
      ,[UNIT_PRICE]
      ,[BUS_STREAM]
      ,[MATERIAL_TYPE]
      ,[PACKLIST_ID]
      ,[PACKLIST_LINE_NO]
      ,[SHIPPED_QTY]
      ,[SHIPPED_DATE]
      ,[INVOICE_DATE]
      ,[INVOICE_ID]
      ,[INVOICE_LINE]
      ,[INVOICE_AMT]
      ,[INVOICE_QTY]
      ,[SHIPPED_AMOUNT]
      ,[UNSHIPPED_AMOUNT]
      ,[ADJUSTED_DUE_DATE]
      ,[SUPPLY_TYPE]
      ,[BASE_ID]
      ,[LOT_ID]
      ,[SPLIT_ID]
      ,[SUB_ID]
      ,[ORDER_STATUS]
      ,[MFG_COUNT]
      ,[FIN_COUNT]
      ,[O_COUNT]
      ,[NULL_COUNT]
      ,[UPD_BUS_STREAM]
      ,[FILTER_PERIOD]
      ,[TARGET_GOALS]
      ,[DESIRED_RLS_DATE]
      ,[CO_DESIRED_SHIP_DATE]
      ,[ON_TIME1]
      ,[LATE1]
      ,[On Time?]
      ,[TOTAL QTY]
      ,[LATE]
      ,[ON TIME]
      ,[Start of Month]
      ,[RowID]
      ,[USER_6]
      ,[BASE_TABLE]

)

SELECT [CTE]
      ,[CUSTOMER_ID]
      ,[CUST_ORDER_ID]
      ,[COL_LINE_NO]
      ,[ORDER_DATE]
      ,[CREATE_DATE]
      ,[DESIRED_SHIP_DATE]
      ,[FILTER_CASE]
      ,[FILTER_DATE]
      ,[CO_STATUS]
      ,[UPDATE_USING_MISC_REF]
      ,[SERVICE_CHARGE_ID]
      ,[LINE_TYPE]
      ,[LINE_ITEM]
      ,[CHARGE_TYPE]
      ,[CUST_PART_DESC]
      ,[COL_PARTID]
      ,[P2ID]
      ,[PART_ID]
      ,[DESCRIPTION]
      ,[PART_PROD_CODE]
      ,[PART_COMM_CODE]
      ,[PLANNER_USER_ID]
      ,[BUYER_USER_ID]
      ,[REASONING]
      ,[SHIP_SHORT]
      ,[ORDER_QTY]
      ,[TOTAL_SHIPPED_QTY]
      ,[REMQTY]
      ,[UNSHIPPEDQTY]
      ,[UNIT_PRICE]
      ,[BUS_STREAM]
      ,[MATERIAL_TYPE]
      ,[PACKLIST_ID]
      ,[PACKLIST_LINE_NO]
      ,[SHIPPED_QTY]
      ,[SHIPPED_DATE]
      ,[INVOICE_DATE]
      ,[INVOICE_ID]
      ,[INVOICE_LINE]
      ,[INVOICE_AMT]
      ,[INVOICE_QTY]
      ,[SHIPPED_AMOUNT]
      ,[UNSHIPPED_AMOUNT]
      ,[ADJUSTED_DUE_DATE]
      ,[SUPPLY_TYPE]
      ,[BASE_ID]
      ,[LOT_ID]
      ,[SPLIT_ID]
      ,[SUB_ID]
      ,[ORDER_STATUS]
      ,[MFG_COUNT]
      ,[FIN_COUNT]
      ,[O_COUNT]
      ,[NULL_COUNT]
      ,[UPD_BUS_STREAM]
      ,[FILTER_PERIOD]
      ,[TARGET_GOALS]
      ,[DESIRED_RLS_DATE]
      ,[CO_DESIRED_SHIP_DATE]
      ,[ON_TIME1]   -- used for on time delivery calculation
      ,[LATE1]
      ,[On Time?]
      ,[TOTAL QTY]
      ,[LATE]
      ,[ON TIME]
      ,[Start of Month]
      ,[RowID]
      ,[USER_6]
      ,[BASE_TABLE]
  FROM  LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT
;


/** 

SELECT ADJUSTED_DUE_DATE, COUNT(*) COUNTOF FROM 
LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT GROUP BY ADJUSTED_DUE_DATE
ORDER BY ADJUSTED_DUE_DATE

SELECT *
FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT_01
WHERE ADJUSTED_DUE_DATE = '19000101';

SELECT *
FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT

SELECT
    BUS_STREAM
    ,COUNT(*) CountOf 
FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT_01
GROUP BY BUS_STREAM;


**/

GO


