USE [LIVESupplemental]
GO

/****** Object:  StoredProcedure [dbo].[sp_BOE_Billing_Core_Feed_01]    Script Date: 8/24/2026 11:47:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
williamt 8/20

feed table LIVESupplemental.dbo.Feed_02_Core_BOE_Billing

EXEC sp_BOE_Billing_Core_Feed_01 @start= '2025-01-01', @end = '2026-08-31' 

Select top 10 
   PackSlip, [unit price], [extended dollars], [expedite dollars], [special fees], [setup hours], [run hours], [expedite hours], [pack slips / date], [invoice id], [comments]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing

select

Select 
sproc, sum([extended dollars]) [extended dollars]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
group by sproc

select sproc, sum([EXTENDED DOLLARS]) [EXTENDED DOLLARS]
from LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
group by sproc

I want to updte Feed_02_Core_BOE_Billing
Documentation\Schema\Data_Models\Customer_Order\Custom_Unlinked_Billing\999.9 sp_BOE_Billing_Core_Feed_01.sql
with the de-duplication logic from Documentation\Schema\Data_Models\Customer_Order\Shipping\sp_BOE_Billing_Core_Feed_01_PRB.21 Dups.sql

*********************************************************************************************/

ALTER PROCEDURE [dbo].[sp_BOE_Billing_Core_Feed_01](@START DATE, @END DATE) AS

IF OBJECT_ID('tempdb..#RESULTS') IS NOT NULL DROP TABLE #RESULTS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

-----------------------------> BOE QUERIES
--DECLARE @START DATE = DATEADD(YEAR,-1,DATEADD(DAY,1,(EOMONTH(DATEADD(MONTH,-1,GETDATE()))))),
--@END DATE = GETDATE()-1

--  DECLARE @START DATE = '2026-06-01';
--  DECLARE @END DATE = GETDATE()
;
IF OBJECT_ID('tempdb..#BOE_BILLING') IS NOT NULL DROP TABLE #BOE_BILLING

-- -- drop table LIVESupplemental.dbo.Feed_02_Core_BOE_Billing

IF OBJECT_ID('LIVESupplemental.dbo.Feed_02_Core_BOE_Billing') IS NULL
BEGIN

CREATE TABLE LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
	(
	  [SPROC] NVARCHAR(15)
	, [COST ITEM] NVARCHAR(20)
	, [POS] NVARCHAR(20)
	, [PART NUMBER] NVARCHAR(50)
	, [RAMAC] NVARCHAR(50)
	, [BILLED QTY] FLOAT
	, [UNIT PRICE] FLOAT
	, [EXTENDED DOLLARS] FLOAT
	, [EXPEDITE DOLLARS] FLOAT
	, [SPECIAL FEES] FLOAT  
	, [SERVICE_FEES] [int] NULL
	, [SETUP HOURS] [decimal](14,2)
	, [RUN HOURS] [decimal](14,2)
	, [EXPEDITE HOURS] FLOAT
	, [PACK SLIPS / DATE] NVARCHAR(MAX)
	, [INVOICE ID] NVARCHAR(MAX)  
	, [COMMENTS] NVARCHAR(MAX)
	, [SORTATION] NVARCHAR(1)
    , [PackSlip] NVARCHAR(MAX)
	, CUST_ORDER_ID NVARCHAR(15)
	, COL_LINE_NO smallint
	)
END

CREATE TABLE #BOE_BILLING
	(
	  [SPROC] NVARCHAR(15)
	, [COST ITEM] NVARCHAR(20)
	, [POS] NVARCHAR(20)
	, [PART NUMBER] NVARCHAR(50)
	, [RAMAC] NVARCHAR(50)
	, [BILLED QTY] FLOAT
	, [UNIT PRICE] FLOAT
	, [EXTENDED DOLLARS] FLOAT
	, [EXPEDITE DOLLARS] FLOAT
	, [SPECIAL FEES] FLOAT  
	, [SERVICE_FEES] [int] NULL
	, [SETUP HOURS] [decimal](14,2)
	, [RUN HOURS] [decimal](14,2)
	, [EXPEDITE HOURS] FLOAT
	, [PACK SLIPS / DATE] NVARCHAR(MAX)
	, [INVOICE ID] NVARCHAR(MAX)  
	, [COMMENTS] NVARCHAR(MAX)
	, [SORTATION] NVARCHAR(1)
	, CUST_ORDER_ID NVARCHAR(15)
	, COL_LINE_NO smallint
	)

	-- BOE_BILLING_605, BOE_BILLING_ASSY, BOE_BILLING_MFG, BOE_BILLING_FINISH, BOE_BILLING_5AXIS, BOE_BILLING_BOLTBOARDS, BOE_BILLING_EME
INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_605 @START, @END
INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_ASSY @START, @END
INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_MFG @START, @END   
INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_FINISH @START, @END 
INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_5AXIS @START, @END 
-- INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_BOLTBOARDS @START, @END
-- INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_EME @START, @END 

CREATE CLUSTERED INDEX CL_IDX_RAMAC ON #BOE_BILLING (RAMAC)
truncate table LIVESupplemental.dbo.Feed_02_Core_BOE_Billing;

insert into LIVESupplemental.dbo.Feed_02_Core_BOE_Billing(
    
      [SPROC]
    , [COST ITEM]
    , [POS]
    , [PART NUMBER]
    , [RAMAC]
    , [BILLED QTY]
    , [UNIT PRICE]
    , [EXTENDED DOLLARS]
    , [EXPEDITE DOLLARS]
    , [SPECIAL FEES]  
    , [SERVICE_FEES] 
    , [SETUP HOURS] 
    , [RUN HOURS] 
    , [EXPEDITE HOURS] 
    , [PACK SLIPS / DATE] 
    , [INVOICE ID]   
    , [COMMENTS] 
    , [SORTATION]

    , CUST_ORDER_ID 
	, COL_LINE_NO

    , [PackSlip]
)
-- parse PackSlip
SELECT
      CAST([SPROC] AS NVARCHAR(15)) AS [SPROC]
    , CAST([COST ITEM] AS NVARCHAR(20)) AS [COST ITEM]
    , CAST([POS] AS NVARCHAR(20)) AS [POS]
    , CAST([PART NUMBER] AS NVARCHAR(50)) AS [PART NUMBER]
    , CAST([RAMAC] AS NVARCHAR(50)) AS [RAMAC]
    , CAST([BILLED QTY] AS FLOAT) AS [BILLED QTY]
    , CAST([UNIT PRICE] AS FLOAT) AS [UNIT PRICE]
    , CAST([EXTENDED DOLLARS] AS FLOAT) AS [EXTENDED DOLLARS]
    , CAST([EXPEDITE DOLLARS] AS FLOAT) AS [EXPEDITE DOLLARS]
    , CAST([SPECIAL FEES] AS FLOAT) AS [SPECIAL FEES]
    , CAST([SERVICE_FEES] AS INT) AS [SERVICE_FEES]
    , CAST([SETUP HOURS] AS DECIMAL(14,2)) AS [SETUP HOURS]
    , CAST([RUN HOURS] AS DECIMAL(14,2)) AS [RUN HOURS]
    , CAST([EXPEDITE HOURS] AS FLOAT) AS [EXPEDITE HOURS]
    , CAST([PACK SLIPS / DATE] AS NVARCHAR(MAX)) AS [PACK SLIPS / DATE]
    , CAST([INVOICE ID] AS NVARCHAR(MAX)) AS [INVOICE ID]
    , CAST([COMMENTS] AS NVARCHAR(MAX)) AS [COMMENTS]
    , CAST([SORTATION] AS NVARCHAR(1)) AS [SORTATION]
    , CAST(CUST_ORDER_ID as NVARCHAR(15)) as CUST_ORDER_ID
	, CAST(COL_LINE_NO as smallint) as COL_LINE_NO

-- please include packslip field in temp table and feed table, and parse the first pack slip from the list of pack slips in the feed table
	,CASE
    WHEN CHARINDEX(',', [PACK SLIPS / DATE]) > 0
        THEN cast(
		    LEFT([PACK SLIPS / DATE], CHARINDEX(',', [PACK SLIPS / DATE]) - 1)
			  AS NVARCHAR(MAX))
    ELSE cast(
	     [PACK SLIPS / DATE]
		    AS NVARCHAR(MAX))
	END AS PackSlip
FROM #BOE_BILLING;

GO


