USE [LIVESupplemental]
GO

/****** Object:  StoredProcedure [dbo].[sp_BOE_Billing_Core_Feed_01]    Script Date: 8/24/2026 11:47:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
williamt 8/20

## Shipments Core Feed 1

```sql
SELECT * FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement 
WHERE FILTER_DATE >= '2025-01-01'
```


## BOE Billing Core Feed 2

```sql
Select top 10 
   SPROC, PackSlip, CUST_ORDER_ID, COL_LINE_NO , [unit price], [extended dollars], [expedite dollars], [special fees], [setup hours], [run hours], [expedite hours], [pack slips / date], [invoice id], [comments]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
WHERE PACKSLIP IS NOT NULL

Select top 10 
   SPROC, PackSlip, CUST_ORDER_ID, COL_LINE_NO , [unit price], [extended dollars], [expedite dollars], [special fees], [setup hours], [run hours], [expedite hours], [pack slips / date], [invoice id], [comments]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
WHERE PACKSLIP IS NULL
```

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

- 1 -
Select SPROC, PackSlip,CUST_ORDER_ID, COL_LINE_NO , [unit price], [extended dollars], [expedite dollars], [special fees], [setup hours]
, [run hours], [expedite hours], [pack slips / date], [invoice id], [comments]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
where 1=1
 -- AND [PackSlip] =
 -- AND CUST_ORDER_ID =
 -- AND COL_LINE_NO =

 AND CUST_ORDER_ID IN (
 '002064831'
,'002064829'
,'002061274'
,'002059559'
,'002057553'
,'002066912'
)

Select SPROC, PackSlip, CUST_ORDER_ID, COL_LINE_NO 
,*
--,PackSlip, [unit price], [extended dollars], [expedite dollars], [special fees], [setup hours]
--, [run hours], [expedite hours], [pack slips / date], [invoice id], [comments]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
where 1=1
 and [part number] = '453A2610-58';
--AND [PackSlip] IS NULL 

SELECT * 
FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement 
WHERE FILTER_DATE >= '2025-01-01'

 AND CUST_ORDER_ID IN (
 '002064831'
,'002064829'
,'002061274'
,'002059559'
,'002057553'
,'002066912'
)
ORDER BY CUST_ORDER_ID

Transact - ETL BOE_Billing Core Feed 2

DECLARE @START1 DATE = DATEADD(YEAR,-2,DATEADD(DAY,1,(EOMONTH(DATEADD(MONTH,-1,GETDATE()))))),
@END1 DATE = GETDATE()-1

EXEC sp_BOE_Billing_Core_Feed_01 @start= @START1, @end = @END1 


*********************************************************************************************/

ALTER PROCEDURE [dbo].[sp_BOE_Billing_Core_Feed_01](@START DATE, @END DATE) AS

IF OBJECT_ID('tempdb..#RESULTS') IS NOT NULL DROP TABLE #RESULTS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

-----------------------------> BOE QUERIES
--DECLARE @START DATE = DATEADD(YEAR,-2,DATEADD(DAY,1,(EOMONTH(DATEADD(MONTH,-1,GETDATE()))))),
--@END DATE = GETDATE()-1

--DECLARE @START DATE = '2026-01-01';
--DECLARE @END DATE = GETDATE()
;
IF OBJECT_ID('tempdb..#BOE_BILLING') IS NOT NULL DROP TABLE #BOE_BILLING
IF OBJECT_ID('tempdb..#Feed_02_STG') IS NOT NULL DROP TABLE #Feed_02_STG
IF OBJECT_ID('tempdb..#Tester') IS NOT NULL DROP TABLE #Tester

CREATE TABLE #Feed_02_STG
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

IF OBJECT_ID('LIVESupplemental.dbo.Feed_02_Core_BOE_Billing_stg') IS NULL
BEGIN

CREATE TABLE LIVESupplemental.dbo.Feed_02_Core_BOE_Billing_stg
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

INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_605_unsh @START, @END
INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_ASSY_unsh @START, @END
INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_MFG_unsh @START, @END   
INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_FINISH_unsh @START, @END 
INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_5AXIS_unsh @START, @END 
-- INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_BOLTBOARDS @START, @END
-- INSERT INTO #BOE_BILLING EXEC Live.dbo.usp_BOE_BILLING_EME @START, @END 



CREATE CLUSTERED INDEX CL_IDX_RAMAC ON #BOE_BILLING (RAMAC)


insert into #Feed_02_STG (   -- -- LIVESupplemental.dbo.Feed_02_Core_BOE_Billing(
    
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

    , CUST_ORDER_ID -- aligned
	, COL_LINE_NO   -- aligned

    , [PackSlip]  -- aligned
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

CREATE CLUSTERED INDEX CL_IDX_feed2_RAMAC ON #Feed_02_STG (RAMAC);

-- -- SELECT * FROM #Feed_02_STG where [part number] like '453A2610-58';
-- -- SELECT sproc, count(*) countof FROM #Feed_02_STG where [part number] like '453A2610-58' group by sproc;

-- ~22 line 290

-- ONE ROW PER -------------------------------------------------------------
-- TEMP TABLE IN TEST
--
-- ------------------------------------------------------------------------

WITH PREaGG AS(
    -- STEP: clean and prepare for aggregation
Select 
    row_number() over (partition by [PackSlip],CUST_ORDER_ID, COL_LINE_NO order by [PackSlip]) as row_num,
    SPROC, [PackSlip], CUST_ORDER_ID, COL_LINE_NO
    ,[Billed qty],[PACK SLIPS / DATE]
    , ramac
    , [PART NUMBER]
    , [INVOICE ID]
    , [COMMENTS]
    , [SORTATION]
    , [EXPEDITE DOLLARS]
    , [SPECIAL FEES]
    , [SERVICE_FEES]
    , [SETUP HOURS]
    , [RUN HOURS]
    , [EXPEDITE HOURS]
    
    ,CAST([extended dollars] AS decimal(18,2)) AS [extended dollars]
    ,CAST([unit price] AS decimal(18,2)) AS [unit price]
FROM #Feed_02_STG 
where 1 = 1 

)
--select * from PREaGG -- where [part number] like '453A2610-58';
, POST_AGG_0 AS(
  -- Step: aggregate duplicates and normalize
SELECT
     PACKSLIP, CUST_ORDER_ID, COL_LINE_NO, [PART NUMBER]

   , STRING_AGG(row_num, ', ') AS row_num
	   , STRING_AGG(SPROC, ', ') AS SPROC
		  , STRING_AGG([PACK SLIPS / DATE], ', ') AS [PACK SLIPS / DATE]
				, STRING_AGG(ramac, ', ') AS ramac
				  ------ , STRING_AGG([PART NUMBER], ', ') AS [PART NUMBER]
					   , STRING_AGG([INVOICE ID], ', ') AS [INVOICE ID]
   , MAX([Billed qty]) AS [Billed qty]
   , SUM([extended dollars]) AS [extended dollars]
		 , SUM([EXPEDITE DOLLARS]) AS [EXPEDITE DOLLARS]
			 , SUM([SPECIAL FEES]) AS [SPECIAL FEES]
				 , SUM([SERVICE_FEES]) AS [SERVICE_FEES]
					 , SUM([SETUP HOURS]) AS [SETUP HOURS]
					    , SUM([RUN HOURS]) AS [RUN HOURS]
					       , SUM([EXPEDITE HOURS]) AS [EXPEDITE HOURS]
   , NULL AS [unit price]

FROM PREaGG
GROUP BY PACKSLIP, CUST_ORDER_ID, COL_LINE_NO, [PART NUMBER]
)
-- -- SELECT * FROM POST_AGG_0 where [part number] = '453A2610-58';

 , Norm As (
  -- Step: normalize unit price
select 
    PACKSLIP
  , row_num
  , SPROC
  , ramac
  , [PART NUMBER]
  , [Billed qty]
  , [extended dollars]
  , [PACK SLIPS / DATE]
  , [EXPEDITE DOLLARS]
  , [SPECIAL FEES]
  , [SERVICE_FEES]
  , [SETUP HOURS]
  , [RUN HOURS]
  , [EXPEDITE HOURS]
  , [INVOICE ID]
  , NULL AS [COMMENTS]
  , NULL AS [SORTATION]
  , CAST( 
      [extended dollars] / NULLIF([Billed qty],0)
   AS decimal(18,2)) AS [unit price]
    , CUST_ORDER_ID, COL_LINE_NO
from POST_AGG_0
)
---

, Align as (
  -- Step: align normalized data for final output
  select 
  row_number() over (partition by [PackSlip],CUST_ORDER_ID, COL_LINE_NO order by [PackSlip]) as row_num,
        [SPROC]
    , NULL AS [COST ITEM]
    , NULL AS [POS]
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

    , CUST_ORDER_ID -- aligned
	, COL_LINE_NO   -- aligned

    , [PackSlip]  -- aligned
  from Norm
)
select * 
   INTO #RESULTS
from Align;

-- select * from #RESULTS where [part number] like '453A2610-58';

--truncate table LIVESupplemental.dbo.Feed_02_Core_BOE_Billing;
truncate table LiveSupplemental.dbo.Feed_02_Core_BOE_Billing_stg;

--insert into LIVESupplemental.dbo.Feed_02_Core_BOE_Billing(
insert into LiveSupplemental.dbo.Feed_02_Core_BOE_Billing_stg(
    
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

    , CUST_ORDER_ID -- aligned
	, COL_LINE_NO   -- aligned

    , [PackSlip]  -- aligned
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
	, CAST(PackSlip as NVARCHAR(15)) as PackSlip

FROM #RESULTS;
-- SELECT * FROM #RESULTS where [part number] = '453A2610-58'

-- 
/*********************************************************************************************
  SELECT * FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing where [part number] = '453A2610-58'

 SELECT * from
 (
 select CUST_ORDER_ID, COL_LINE_NO, PackSlip,
     row_number() over (partition by CUST_ORDER_ID, COL_LINE_NO order by [PackSlip]) as row_num
 FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
 ) x
 where 1=1
 and x.row_num >1

 SELECT
    CUST_ORDER_ID,
    COL_LINE_NO,
    PackSlip,
    COUNT(*) AS cnt
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
GROUP BY
    CUST_ORDER_ID,
    COL_LINE_NO,
    PackSlip
HAVING COUNT(*) > 1;

SELECT
    CUST_ORDER_ID,
    COL_LINE_NO,
    COUNT(*) AS cnt
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
WHERE PackSlip IS NULL
GROUP BY
    CUST_ORDER_ID,
    COL_LINE_NO
HAVING COUNT(*) > 1;
**************************************************/

-- build using CUST_ORDER_ID, COL_LINE_NO, Packlist
------------------------------------------------------
--
--  Merge
--
-- -----------------------------------------------------

SET XACT_ABORT ON;
DECLARE
    @TotalRows INT,
    @DeletedRows INT = 0,
    @MaxDeletePct DECIMAL(9,4) = 0.9900;
SELECT @TotalRows = COUNT(*)
FROM [LIVESupplemental].[dbo].[Feed_02_Core_BOE_Billing];
DECLARE @MergeOutput TABLE
(
    ActionType NVARCHAR(10),
    KeyValue NVARCHAR(4000)
);
BEGIN TRANSACTION;
MERGE [LIVESupplemental].[dbo].[Feed_02_Core_BOE_Billing] AS trgt
USING [LIVESupplemental].[dbo].[Feed_02_Core_BOE_Billing_stg] AS src
/*     ON trgt.[CUST_ORDER_ID] = src.[CUST_ORDER_ID]
    AND trgt.[COL_LINE_NO] = src.[COL_LINE_NO]
    AND trgt.[PackSlip] = src.[PackSlip] */
	
ON  trgt.CUST_ORDER_ID = src.CUST_ORDER_ID
AND trgt.COL_LINE_NO   = src.COL_LINE_NO
AND (
       trgt.PackSlip = src.PackSlip
    OR (trgt.PackSlip IS NULL AND src.PackSlip IS NULL)
    )
WHEN MATCHED AND
(
    ISNULL(trgt.[SPROC], N'') <> ISNULL(src.[SPROC], N'')
    OR ISNULL(trgt.[COST ITEM], N'') <> ISNULL(src.[COST ITEM], N'')
    OR ISNULL(trgt.[POS], N'') <> ISNULL(src.[POS], N'')
    OR ISNULL(trgt.[PART NUMBER], N'') <> ISNULL(src.[PART NUMBER], N'')
    OR ISNULL(trgt.[RAMAC], N'') <> ISNULL(src.[RAMAC], N'')
    OR ISNULL(trgt.[BILLED QTY], -999999) <> ISNULL(src.[BILLED QTY], -999999)
    OR ISNULL(trgt.[UNIT PRICE], -999999) <> ISNULL(src.[UNIT PRICE], -999999)
    OR ISNULL(trgt.[EXTENDED DOLLARS], -999999) <> ISNULL(src.[EXTENDED DOLLARS], -999999)
    OR ISNULL(trgt.[EXPEDITE DOLLARS], -999999) <> ISNULL(src.[EXPEDITE DOLLARS], -999999)
    OR ISNULL(trgt.[SPECIAL FEES], -999999) <> ISNULL(src.[SPECIAL FEES], -999999)
    OR ISNULL(trgt.[SERVICE_FEES], -999999) <> ISNULL(src.[SERVICE_FEES], -999999)
    OR ISNULL(trgt.[SETUP HOURS], -999999) <> ISNULL(src.[SETUP HOURS], -999999)
    OR ISNULL(trgt.[RUN HOURS], -999999) <> ISNULL(src.[RUN HOURS], -999999)
    OR ISNULL(trgt.[EXPEDITE HOURS], -999999) <> ISNULL(src.[EXPEDITE HOURS], -999999)
    OR ISNULL(trgt.[PACK SLIPS / DATE], N'') <> ISNULL(src.[PACK SLIPS / DATE], N'')
    OR ISNULL(trgt.[INVOICE ID], N'') <> ISNULL(src.[INVOICE ID], N'')
    OR ISNULL(trgt.[COMMENTS], N'') <> ISNULL(src.[COMMENTS], N'')
    OR ISNULL(trgt.[SORTATION], N'') <> ISNULL(src.[SORTATION], N'')
)

THEN UPDATE SET
    trgt.[SPROC] = src.[SPROC],
    trgt.[COST ITEM] = src.[COST ITEM],
    trgt.[POS] = src.[POS],
    trgt.[PART NUMBER] = src.[PART NUMBER],
    trgt.[RAMAC] = src.[RAMAC],
    trgt.[BILLED QTY] = src.[BILLED QTY],
    trgt.[UNIT PRICE] = src.[UNIT PRICE],
    trgt.[EXTENDED DOLLARS] = src.[EXTENDED DOLLARS],
    trgt.[EXPEDITE DOLLARS] = src.[EXPEDITE DOLLARS],
    trgt.[SPECIAL FEES] = src.[SPECIAL FEES],
    trgt.[SERVICE_FEES] = src.[SERVICE_FEES],
    trgt.[SETUP HOURS] = src.[SETUP HOURS],
    trgt.[RUN HOURS] = src.[RUN HOURS],
    trgt.[EXPEDITE HOURS] = src.[EXPEDITE HOURS],
    trgt.[PACK SLIPS / DATE] = src.[PACK SLIPS / DATE],
    trgt.[INVOICE ID] = src.[INVOICE ID],
    trgt.[COMMENTS] = src.[COMMENTS],
    trgt.[SORTATION] = src.[SORTATION]

	
WHEN NOT MATCHED BY TARGET THEN
INSERT
(
    [SPROC],
    [COST ITEM],
    [POS],
    [PART NUMBER],
    [RAMAC],
    [BILLED QTY],
    [UNIT PRICE],
    [EXTENDED DOLLARS],
    [EXPEDITE DOLLARS],
    [SPECIAL FEES],
    [SERVICE_FEES],
    [SETUP HOURS],
    [RUN HOURS],
    [EXPEDITE HOURS],
    [PACK SLIPS / DATE],
    [INVOICE ID],
    [COMMENTS],
    [SORTATION],
    [PackSlip],
    [CUST_ORDER_ID],
    [COL_LINE_NO]
)
VALUES
(
    src.[SPROC],
    src.[COST ITEM],
    src.[POS],
    src.[PART NUMBER],
    src.[RAMAC],
    src.[BILLED QTY],
    src.[UNIT PRICE],
    src.[EXTENDED DOLLARS],
    src.[EXPEDITE DOLLARS],
    src.[SPECIAL FEES],
    src.[SERVICE_FEES],
    src.[SETUP HOURS],
    src.[RUN HOURS],
    src.[EXPEDITE HOURS],
    src.[PACK SLIPS / DATE],
    src.[INVOICE ID],
    src.[COMMENTS],
    src.[SORTATION],
    src.[PackSlip],
    src.[CUST_ORDER_ID],
    src.[COL_LINE_NO]
)
WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT $action, CAST(DELETED.[CUST_ORDER_ID] AS NVARCHAR(4000))
INTO @MergeOutput(ActionType, KeyValue);
SELECT @DeletedRows = COUNT(*) FROM @MergeOutput W
WHERE ActionType = 'DELETE';  IF @TotalRows > 0 AND (@DeletedRows * 1.0 / @TotalRows) > @MaxDeletePct 
BEGIN     ROLLBACK;     THROW 50001, 'MERGE aborted: excessive deletes detected.', 1;
 END ELSE BEGIN     COMMIT; END;
