USE [LIVE]
GO

/****** Object:  StoredProcedure [dbo].[SP_SK_ETL03_CUST_SHIP]    Script Date: 8/4/2026 9:24:36 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/* =============================================
-- Author:		JC
-- Create date: 03/25/2025
-- Description:	Data set for PBI_Customer_Shipments01
*/

CREATE PROCEDURE [dbo].SP_SK_ETL03_CUST_SHIP AS

SET NOCOUNT off;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

-- ~block 1
/* Data for new Table LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT to calculate OnTime Delivery */
TRUNCATE TABLE  LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT

INSERT INTO LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT

SELECT A.*, CL.USER_6, 'LIVE' FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement A WITH (NOLOCK)
LEFT JOIN LIVE.dbo.CUST_ORDER_LINE CL WITH (NOLOCK) ON A.CUST_ORDER_ID = CL.CUST_ORDER_ID 
	AND A.COL_LINE_NO = CL.LINE_NO
WHERE A.FILTER_DATE >= '2024-12-24' 
-- ~block 1 /



/*	Exclude all customer orders lines that have CBO in the user defined 6. (Update requested by Monica 24-Apr-2025) 	*/
DELETE FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT
WHERE  COL_UDF6 = 'CBO' AND BUS_STREAM = 'MFG'
DELETE FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT
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
FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT A WITH (NOLOCK)
--INNER JOIN LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
WHERE A.BUS_STREAM = 'CMP-FIN' OR A.BUS_STREAM = 'CMP-MFG' 



/************************************************************************************************ 
				Fix ADJUSTED_DUE_DATE for BUS_STREAM  'FIN' OR 'MFG'
*************************************************************************************************/

/* Fix ADJUSTED_DUE_DATE for BUS_STREAM = 'MFG' take Customer Order Line – Promise Delivery Date
	If the promise delivery date is blank on the customer order line use the customer order header 
	promise delivery date. (Update requested by Monica 24-Apr-2025)	*/
UPDATE A SET A.ADJUSTED_DUE_DATE = 
		IIF(CL.PROMISE_DATE IS NULL, C.DESIRED_SHIP_DATE, CL.PROMISE_DATE)
FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT A WITH (NOLOCK)
INNER JOIN LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
INNER JOIN CUST_ORDER_LINE CL WITH (NOLOCK) ON A.CUST_ORDER_ID = CL.CUST_ORDER_ID and a.COL_LINE_NO = CL.LINE_NO
INNER JOIN CUSTOMER_ORDER C WITH (NOLOCK) ON A.CUST_ORDER_ID = C.ID
WHERE A.CO_DESIRED_SHIP_DATE is not null and a.RowID = b.RowID AND A.BUS_STREAM = 'MFG'

/*	Fix ADJUSTED_DUE_DATE for BUS_STREAM = 'FIN' take Desired Ship Date from CO Header.
	For customers AERMAN and AMTRIB, add 1 day for transportation (Update requested by Monica 24-Apr-2025)  */
UPDATE A SET 
	A.ADJUSTED_DUE_DATE = 
	CASE WHEN A.CUSTOMER_ID = 'AERMAN' OR A.CUSTOMER_ID = 'AMTRIB' 
		THEN DATEADD(DAY, 1, C.DESIRED_SHIP_DATE)
	ELSE C.DESIRED_SHIP_DATE
	END
FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT A WITH (NOLOCK)
INNER JOIN LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
INNER JOIN CUSTOMER_ORDER C WITH (NOLOCK) ON A.CUST_ORDER_ID = C.ID
WHERE A.CO_DESIRED_SHIP_DATE is not null and a.RowID = b.RowID AND A.BUS_STREAM = 'FIN'


/*	Fix ADJUSTED_DUE_DATE for BUS_STREAM = 'FIN_MFG' take Desired Ship Date from CO Header 
	(This category is being phased out.) (Update requested by Monica 24-Apr-2025) */
UPDATE A SET A.ADJUSTED_DUE_DATE = C.DESIRED_SHIP_DATE
FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT A WITH (NOLOCK)
INNER JOIN LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
INNER JOIN CUSTOMER_ORDER C WITH (NOLOCK) ON A.CUST_ORDER_ID = C.ID
WHERE A.CO_DESIRED_SHIP_DATE is not null and a.RowID = b.RowID AND A.BUS_STREAM = 'FIN_MFG'


	/**********************************************************************************/
	/**********************************************************************************/

	DELETE FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT
	WHERE TOTAL_SHIPPED_QTY = 0 
	AND ADJUSTED_DUE_DATE >= DATEADD( DAY, 1, CAST(GETDATE() AS DATE) )



	/**********************************************************************************/
	/**********************************************************************************/
/************************************************************************************************ 
						Fix OnTime and Late after Fix ADJUSTED_DUE_DATE
*************************************************************************************************/
UPDATE A SET A.ON_TIME1 = IIF(A.[FILTER_DATE] <= A.ADJUSTED_DUE_DATE, 1, 0),
			A.LATE1 =  IIF(A.[FILTER_DATE] <= A.ADJUSTED_DUE_DATE, 0, 1)
FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT A WITH (NOLOCK)
INNER JOIN LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID
WHERE A.[ON TIME] is not null and a.RowID = b.RowID 

	/**********************************************************************************/
	/**********************************************************************************/
/************************************************************************************************ 
						Insert to final table
*************************************************************************************************/

TRUNCATE TABLE  LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT_01

INSERT INTO LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT_01

SELECT * FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT

;

GO


