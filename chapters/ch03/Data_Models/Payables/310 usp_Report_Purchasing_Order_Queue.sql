USE [LIVE]
GO

/****** Object:  StoredProcedure [report].[usp_Report_Purchasing_Order_Queue]    Script Date: 6/30/2026 7:46:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- create schema report

 /**********************************************************************************************
Report.usp_Report_Purchasing_Order_Queue
Description:	Fields for MRP Table
Sample:			Purchasing - Planned Order Queue

Date        Modified By         Change Description
----------  ------------------  ------------------------------------------------------------
02/18/2020	William Thompson	Created pivot table from MRP Table query.
03/04/2020	William Thompson	Vertical zero fill = from Part join cross join #MRP_LinesS join #result.part_id
03/23/2020	William Thompson	Combined Aggregate table code branch with MPS Main branch.
03/23/2020  William Thompson	Forked code to projected on hand code base.
5/8/2020	William Thompson    Combined planned orders for demand (pegged) to planned order supply

MRP Folders
-----------------
MRP.Supply.1 Gross Requirements
MRP.Supply.2 Scheduled receipts
MRP.Supply.3 Projected on Hand
MRP.Supply.4 Net Requirements
MRP.Supply.5 Planned Order Receipts  **
MRP.Supply.6 Planned Order Releases

declare @part_id nvarchar(255) = NULL  -- '151W0231-24'  --74A588133-2009 -- 847Z3110-319 -- 866Z9009-7   -- 151W0231-2 -- '100T1430-87' -- 151W0231-24  -- 6AL4VE-1278 -- '151W0231-2'

exec Report.usp_Report_Purchasing_Order_Queue 'Raw Material'
**********************************************************************************************/

---CREATE procedure [report].[usp_Report_Purchasing_Order_Queue]
declare
   @COMMODITY_CODE AS NVARCHAR(15) --  = 'Raw Material'
-- as  -- 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

SET @COMMODITY_CODE = nullif(@COMMODITY_CODE,'<ALL>')

declare @part_id nvarchar(255) = NULL -- '2-162-N70' -- '2-162-N70' -- '151W0231-24'  --74A588133-2009 -- 847Z3110-319 -- 866Z9009-7   -- 151W0231-2 -- '100T1430-87' -- 151W0231-24  -- 6AL4VE-1278 -- '151W0231-2'


IF OBJECT_ID('tempdb..#Supply') IS NOT NULL DROP TABLE #Supply
IF OBJECT_ID('tempdb..#ResultsS') IS NOT NULL DROP TABLE #ResultsS
IF OBJECT_ID('tempdb..#zero_fillS') IS NOT NULL DROP TABLE #zero_fillS
IF OBJECT_ID('tempdb..#bucketsS') IS NOT NULL DROP TABLE #bucketsS
IF OBJECT_ID('tempdb..#processDatesS') IS NOT NULL DROP TABLE #processDatesS
IF OBJECT_ID('tempdb..#MRP_LinesS') IS NOT NULL DROP TABLE #MRP_LinesS
IF OBJECT_ID('tempdb..#MRPConfigS') IS NOT NULL DROP TABLE #MRPConfigS

IF OBJECT_ID('tempdb..#SupplySet') IS NOT NULL DROP TABLE #SupplySet
IF OBJECT_ID('tempdb..#DemandSet') IS NOT NULL DROP TABLE #DemandSet

SELECT
 
   MRP_LINE_CD
 , SortOrder
 , RequiredDate
 , TheZero	-- > required_Qty for vertical fill
 , SiteID
 , [dsl_Line_Type]
 , MRP_Side
 into #MRPConfigS
FROM (VALUES
	 ('CONF', 1, getdate(),0,'SK01','S',NULL)
	,('HEAD', 2, getdate(),0,'SK01','H',NULL)
	) AS sub 
	(MRP_LINE_CD, SortOrder, RequiredDate, TheZero, SiteID,[dsl_Line_Type],MRP_Side)
 
CREATE TABLE #MRP_LinesS(
	end_of_previous_month_x date null,

	[PART_ID] [nvarchar](30) NULL,
	[DW_Query_Section_ID] [int] NOT NULL,
	[Status] [nvarchar](1) NULL,
	[REQUIRED_DATE ] [datetime] NOT NULL,
	[Required_Qty] [decimal](14, 4) NULL,
	[Received_Qty] [decimal](14, 4) NULL,
	[Allocated_Qty] [decimal](14, 4) NULL,
	[Fulfilled_Qty] [decimal](14, 4) NULL,
	[dsl_type] [nvarchar](2) NULL,
	[dsl_base_id] [nvarchar](30)  NULL,
	[dsl_line] [nvarchar](22) NULL,
	[dsl_split_id] [nvarchar](3) NULL,
	[dsl_sub_id] [nvarchar](3) NULL,
	[DESIRED_RLS_DATE] [datetime] NULL,
	[piece_no] [int] NULL,
	[RLS_DATE] [datetime] NULL,
	[WAREHOUSE_ID] [nvarchar](15) NULL,
	[WBS_CODE] [nvarchar](30) NULL,
	[SITE_ID] [nvarchar](15) NOT NULL,

	[dsl_line_status] [nvarchar](30) NULL,
	[dsl_Line_Type] [nvarchar](30) NULL,
	[Lead_Time] [int] NULL,
	[SafetyStock] [int] NULL,


	Gross_Requirements INT NULL,
	Scheduled_Receipts INT NULL,
	Planned_Order_Releases int,	
	Planned_Order_Release_Date datetime,
	Projected_On_Hand INT NULL,
	Net_Requirements INT NULL,
	Planned_Order_Receipts INT NULL,

	MRP_Side VARCHAR(4) NULL,			-- a for recepts, b for release (dataset)
	MRP_Line_CD VARCHAR(8),
	SortOrder	INT NULL,
	FLD1		INT NULL,
	FLD2		INT NULL,
	FLD3		INT	NULL,
	FLD4		INT NULL,
	FLD5		INT NULL	
	
) 

DECLARE @RequiredDate_0 DATETIME = GETDATE()  

insert into #MRP_LinesS (
	DW_Query_Section_ID
	,MRP_LINE_CD
	,SortOrder
	,Required_Date
	,Required_Qty  
	,SITE_ID
	,dsl_Line_Type
	,MRP_Side
)

SELECT
   TheZero
 , MRP_LINE_CD, SortOrder, RequiredDate
 , TheZero	 
 , SiteID
 , [dsl_Line_Type]
 , MRP_Side
FROM (VALUES
	 ('GROS', 1, getdate(),0,'SK01','S',NULL)
	,('SCHE', 2, getdate(),0,'SK01','S',NULL)
	,('PROJ', 3, getdate(),0,'SK01','S',NULL)
	,('NETR', 4, getdate(),0,'SK01','S',NULL)
	,('PREC', 5, getdate(),0,'SK01','S','A')
	,('PREL', 6, getdate(),0,'SK01','S','B')
	
	) AS sub 
	(MRP_LINE_CD, SortOrder, RequiredDate, TheZero, SiteID,[dsl_Line_Type],MRP_Side)


CREATE TABLE #zero_fillS(
	end_of_previous_month_x date null,

	[PART_ID] [nvarchar](30) NULL,
	[DW_Query_Section_ID] [int] NOT NULL,
	[Status] [nvarchar](1) NULL,
	[REQUIRED_DATE ] [datetime] NOT NULL,
	[Required_Qty] [decimal](14, 4) NULL,
	[Received_Qty] [decimal](14, 4) NULL,
	[Allocated_Qty] [decimal](14, 4) NULL,
	[Fulfilled_Qty] [decimal](14, 4) NULL,
	[dsl_type] [nvarchar](2) NULL,
	[dsl_base_id] [nvarchar](30)  NULL,
	[dsl_line] [nvarchar](22) NULL,
	[dsl_split_id] [nvarchar](3) NULL,
	[dsl_sub_id] [nvarchar](3) NULL,
	[DESIRED_RLS_DATE] [datetime] NULL,
	[piece_no] [int] NULL,
	[RLS_DATE] [datetime] NULL,
	[WAREHOUSE_ID] [nvarchar](15) NULL,
	[WBS_CODE] [nvarchar](30) NULL,
	[SITE_ID] [nvarchar](15) NOT NULL,

	month_x  int,
	PeriodDesign  varchar(30) , 
	[Month_Num]  int,
	Year_Num  int,

	[dsl_line_status] [nvarchar](30) NULL,
	[dsl_Line_Type] [nvarchar](30) NULL,
	[Lead_Time] [int] NULL,
	[SafetyStock] [int] NULL,

	Gross_Requirements INT NULL,
	Scheduled_Receipts INT NULL,
	Planned_Order_Releases int,	
	Planned_Order_Release_Date datetime,
	Projected_On_Hand INT NULL,
	Net_Requirements INT NULL,
	Planned_Order_Receipts INT NULL,

	MRP_Side VARCHAR(4) NULL,			
	MRP_Line_CD VARCHAR(8),
	SortOrder	INT NULL,
	FLD1		INT NULL,
	FLD2		INT NULL,
	FLD3		INT	NULL,
	FLD4		INT NULL,
	FLD5		INT NULL	
	
) 


CREATE TABLE #supply(
	[PART_ID] [nvarchar](30) NULL,
	[DW_Query_Section_ID] [int] NOT NULL,
	[Status] [nvarchar](1) NULL,
	[REQUIRED_DATE ] [datetime] NOT NULL,
	[Required_Qty] [decimal](14, 4) NULL,
	[Received_Qty] [decimal](14, 4) NULL,
	[Allocated_Qty] [decimal](14, 4) NULL,
	[Fulfilled_Qty] [decimal](14, 4) NULL,
	[dsl_type] [nvarchar](2) NULL,
	[dsl_base_id] [nvarchar](30) NULL,
	[dsl_line] [nvarchar](22) NULL,
	[dsl_split_id] [nvarchar](3) NULL,
	[dsl_sub_id] [nvarchar](3) NULL,
	[DESIRED_RLS_DATE] [datetime] NULL,
	[piece_no] [int] NOT NULL,
	[RLS_DATE] [datetime] NULL,
	[WAREHOUSE_ID] [nvarchar](15) NULL,
	[WBS_CODE] [nvarchar](30) NULL,
	[SITE_ID] [nvarchar](15) NOT NULL,
    dsl_line_status [nvarchar](30), 
    dsl_Line_Type [nvarchar](30),
    Lead_Time int,
    SafetyStock int,

	Gross_Requirements INT NULL,
	Scheduled_Receipts INT NULL,
	Planned_Order_Releases int,	
	Planned_Order_Release_Date datetime,
	Projected_On_Hand INT NULL,
	Net_Requirements INT NULL,
	Planned_Order_Receipts INT NULL,

	MRP_Side VARCHAR(4) NULL,			 
	MRP_Line_CD VARCHAR(8),
	SortOrder	INT NULL,
	FLD1		INT NULL,
	FLD2		INT NULL,
	FLD3		INT	NULL,
	FLD4		INT NULL,
	FLD5		INT NULL	
	
)

CREATE TABLE #ResultsS(
	[PART_ID] [nvarchar](30) NULL,
	[DW_Query_Section_ID] [int] NOT NULL,
	[Status] [nvarchar](1) NULL,
	[REQUIRED_DATE ] [datetime] NOT NULL,
	[Required_Qty] [decimal](14, 4) NULL,
	[Received_Qty] [decimal](14, 4) NULL,
	[Allocated_Qty] [decimal](14, 4) NULL,
	[Fulfilled_Qty] [decimal](14, 4) NULL,
	[dsl_type] [nvarchar](2) NULL,
	[dsl_base_id] [nvarchar](30) NULL,
	[dsl_line] [nvarchar](22) NULL,
	[dsl_split_id] [nvarchar](3) NULL,
	[dsl_sub_id] [nvarchar](3) NULL,
	[DESIRED_RLS_DATE] [datetime] NULL,
	[piece_no] [int] NOT NULL,
	[RLS_DATE] [datetime] NULL,
	[WAREHOUSE_ID] [nvarchar](15) NULL,
	[WBS_CODE] [nvarchar](30) NULL,
	[SITE_ID] [nvarchar](15) NOT NULL,
    dsl_line_status [nvarchar](30),
    dsl_Line_Type [nvarchar](30),
    Lead_Time int,
    SafetyStock int,
	Gross_Requirements INT NULL,
	Scheduled_Receipts INT NULL,
	Planned_Order_Releases int,	
	Planned_Order_Release_Date datetime,

	Projected_On_Hand INT NULL,
	Net_Requirements INT NULL,
	Planned_Order_Receipts INT NULL,

	MRP_Side VARCHAR(4) NULL,			-- a for recepts, b for release (dataset)
	MRP_Line_CD VARCHAR(8),
	SortOrder	INT NULL,
	FLD1		INT NULL,
	FLD2		INT NULL,
	FLD3		INT	NULL,
	FLD4		INT NULL,
	FLD5		INT NULL	
)



--declare @part_id nvarchar(255) = '74A588133-2009'  --'232A4440-18'  --'151W0231-24'   --  '100T1430-87' -- 151W0231-24  -- 6AL4VE-1278 -- '151W0231-2'


-- select * from #ResultsS
INSERT INTO #supply(

 [PART_ID]
      ,[DW_Query_Section_ID]
      ,[Status]
      ,[REQUIRED_DATE ]
      ,[Required_Qty]
      ,[Received_Qty]
      ,[Allocated_Qty]
      ,[Fulfilled_Qty]
      ,[dsl_type]
      ,[dsl_base_id]
      ,[dsl_line]
      ,[dsl_split_id]
      ,[dsl_sub_id]
      ,[DESIRED_RLS_DATE]
      ,[piece_no]
      ,[RLS_DATE]
      ,[WAREHOUSE_ID]
      ,[WBS_CODE]
      ,[SITE_ID]

   ,dsl_line_status
   ,dsl_Line_Type 
   ,Lead_Time 
   ,SafetyStock 

   	,Gross_Requirements
	,Scheduled_Receipts

   	,Planned_Order_Releases 	
	,Planned_Order_Release_Date 
	
	,Projected_On_Hand
	,Net_Requirements
	,Planned_Order_Receipts

	,MRP_Side
	,MRP_LINE_CD
	,SortOrder
	,FLD1
	,FLD2
	,FLD3
	,FLD4
	,FLD5	

)
SELECT

 [PART_ID]
      ,[DW_Query_Section_ID]
      ,[Status]
      ,[REQUIRED_DATE ]
      ,[Required_Qty]
      ,[Received_Qty]
      ,[Allocated_Qty]
      ,[Fulfilled_Qty]
      ,[dsl_type]
      ,[dsl_base_id]
      ,[dsl_line]
      ,[dsl_split_id]
      ,[dsl_sub_id]
      ,[DESIRED_RLS_DATE]
      ,[piece_no]
      ,[RLS_DATE]
      ,[WAREHOUSE_ID]
      ,[WBS_CODE]
      ,[SITE_ID]

   ,dsl_line_status
   ,dsl_Line_Type 
   ,Lead_Time 
   ,SafetyStock 

   	,Gross_Requirements
	,Scheduled_Receipts

   	,Planned_Order_Releases 	
	,Planned_Order_Release_Date
	,Projected_On_Hand
	,Net_Requirements
	,Planned_Order_Receipts

	,MRP_Side
	,MRP_LINE_CD
	,SortOrder
	,FLD1
	,FLD2
	,FLD3
	,FLD4
	,FLD5

-- drop table WilliamT.Temp1

--INTO WilliamT.Temp1

FROM (

SELECT
   w.PART_ID,
   DW_Query_Section_ID = 1,
   [Status] = W.STATUS,
   REQUIRED_DATE  = ISNULL ( W.DESIRED_WANT_DATE, CONVERT ( DATETIME, N'3999-12-31', 102 ) ),
   Required_Qty = W.DESIRED_QTY,
   Received_Qty = W.RECEIVED_QTY,
   Allocated_Qty =  W.ALLOCATED_QTY,
   Fulfilled_Qty =  W.FULFILLED_QTY,
   dsl_type = W.TYPE,
   dsl_base_id =  W.BASE_ID,
   dsl_line =  W.LOT_ID,
   dsl_split_id = W.SPLIT_ID,
   dsl_sub_id = W.SUB_ID,
   W.DESIRED_RLS_DATE,
   piece_no = 0,  -- projected on hand ??
   CONVERT ( DATETIME, N'3999-12-31', 102 ) RLS_DATE,
   W.WAREHOUSE_ID,
   WBS_CODE,
   SITE_ID,
   dsl_line_status = NULL,
   dsl_Line_Type = NULL,
   Lead_Time = P.PLANNING_LEADTIME,
   SafetyStock = NULL,

   	Gross_Requirements = NULL,
	Scheduled_Receipts = NULL,


   Planned_Order_Releases = NULL, 	
   Planned_Order_Release_Date = NULL,

	Projected_On_Hand = NULL,
	Net_Requirements = NULL,
	Planned_Order_Receipts = NULL,

	MRP_Side = null,
	MRP_LINE_CD = null,
	SortOrder = null,
	FLD1 = null,
	FLD2 = null,
	FLD3 = null,
	FLD4 = null,
	FLD5 = null

FROM
   WORK_ORDER W (nolock)
   INNER JOIN PART P
   ON W.PART_ID = P.ID
WHERE (1=1)
  -- AND W.PART_ID = @P1 
   AND W.PART_ID IN (SELECT ID FROM PART) 
   AND W.SITE_ID IN 
   (
      N'SK01' 
   )
   AND W.TYPE = N'W' 
   AND W.SUB_ID = N'0' 
   AND W.DESIRED_QTY > W.RECEIVED_QTY 
   AND W.WBS_PROJECT = N'N' 
   AND W.STATUS IN 
   (
      N'R',
      N'S',
      N'U',
      N'F',
      N'H' 
   )
   
UNION
SELECT
	CP.PART_ID,
	DW_Query_Section_ID = 2,  -- 2
   W.[STATUS],
   REQUIRED_DATE  =ISNULL ( W.DESIRED_WANT_DATE, CONVERT ( DATETIME, N'3999-12-31', 102 ) ),
   Required_Qty = CP.DESIRED_QTY,
   Received_Qty = CP.RECEIVED_QTY,
   Allocated_Qty = CP.ALLOCATED_QTY,
   Fulfilled_Qty = CP.FULFILLED_QTY,
   dsl_type = W.[TYPE],
   dsl_base_id = W.BASE_ID,
   dsl_line = W.LOT_ID,
   dsl_split_id = W.SPLIT_ID,
   dsl_sub_id = W.SUB_ID,
   DESIRED_RLS_DATE = W.DESIRED_RLS_DATE,
   piece_no =  0,  -- projected on hand ??
   rls_date = CONVERT ( DATETIME, N'3999-12-31', 102 ),
   WAREHOUSE_ID = ISNULL ( CP.WAREHOUSE_ID, W.WAREHOUSE_ID ),
   W.WBS_CODE,
   W.SITE_ID ,

   dsl_line_status = NULL,
   dsl_Line_Type = NULL,
   Lead_Time = P.PLANNING_LEADTIME,
   SafetyStock = NULL,

   	Gross_Requirements = NULL,
	Scheduled_Receipts = NULL,

   Planned_Order_Releases = NULL, 	
   Planned_Order_Release_Date = NULL,

   Projected_On_Hand = NULL,
   Net_Requirements = NULL,
   Planned_Order_Receipts = NULL,
	MRP_Side = null,
	MRP_LINE_CD = null,
	SortOrder = null,
	FLD1 = null,
	FLD2 = null,
	FLD3 = null,
	FLD4 = null,
	FLD5 = null	

FROM
  -- Version 2 
   WORK_ORDER W
   JOIN CO_PRODUCT CP 
   ON CP.WORKORDER_TYPE = N'W' 
   AND CP.WORKORDER_TYPE = W.TYPE 
   AND CP.WORKORDER_BASE_ID = W.BASE_ID 
   AND CP.WORKORDER_LOT_ID = W.LOT_ID 
   AND CP.WORKORDER_SPLIT_ID = W.SPLIT_ID 
   AND CP.WORKORDER_SUB_ID = W.SUB_ID 

   JOIN PART P
   ON CP.PART_ID = P.ID
   

WHERE (1=1)
   -- AND CP.PART_ID = @P2 

   AND W.SITE_ID IN 
   (
      N'SK01' 
   )
   AND CP.DESIRED_QTY > CP.RECEIVED_QTY 
   AND W.WBS_PROJECT = N'N' 
   AND W.STATUS IN 
   (
      N'R',
      N'S',
      N'U',
      N'F',
      N'H' 
   )
UNION
SELECT
   L.PART_ID,  -- 1
   DW_Query_Section_ID = 3,  -- 2
   [Status] = O.STATUS,  -- 3
   REQUIRED_DATE  = ISNULL ( ISNULL ( L.DESIRED_RECV_DATE, O.DESIRED_RECV_DATE ), CONVERT ( DATETIME, N'3999-12-31', 102 ) ),  --4
   Required_Qty = L.ORDER_QTY,  -- 5
   L.TOTAL_RECEIVED_QTY,  -- 6
   L.ALLOCATED_QTY,  -- 7
   L.FULFILLED_QTY,  -- 8
   dsl_type = N'P',  -- 9
   dsl_base_id = O.ID, -- 10
   dsl_line =  LTRIM ( STR ( L.LINE_NO, 22, 0 ) ), -- 11
   dsl_split = N'0',  -- 12
   dsl_sub_id = N'0',  -- 13
   desired_release_date = O.ORDER_DATE,  -- 14
   piece_no =  0,   -- 15
   rls_date = CONVERT ( DATETIME, DATENAME ( YY, O.PRINTED_DATE ) + N'-' + LEFT ( DATENAME ( MM, O.PRINTED_DATE ), 3 ) 
			+ N'-' + DATENAME ( DD, O.PRINTED_DATE ) ),  --16
   warehouse_id = ISNULL ( L.WAREHOUSE_ID, O.WAREHOUSE_ID ) ,  -- 17
   wbs_code = L.WBS_CODE,  -- 18
   site_id = L.SITE_ID,  --19

   dsl_line_status = NULL,
   dsl_Line_Type = NULL,
   Lead_Time = P.PLANNING_LEADTIME,
   SafetyStock = NULL,

   Gross_Requirements = NULL,
   Scheduled_Receipts = NULL,


   Planned_Order_Releases = NULL, 	
   Planned_Order_Release_Date = NULL,

	Projected_On_Hand = NULL,
	Net_Requirements = NULL,
	Planned_Order_Receipts = NULL,

	MRP_Side = null,
	MRP_LINE_CD = null,
	SortOrder = null,
	FLD1 = null,
	FLD2 = null,
	FLD3 = null,
	FLD4 = null,
	FLD5 = null
FROM
  -- Version 2
   PURC_ORDER_LINE L
   JOIN PURCHASE_ORDER O 
   ON L.PURC_ORDER_ID = O.ID
   
   JOIN PART P
   ON L.PART_ID = P.ID

WHERE (1=1)

   -- AND L.PART_ID = @P3 
   and l.PART_ID IN (SELECT ID FROM PART)
   AND L.SITE_ID IN 
   (
      N'SK01' 
   )
   AND L.ORDER_QTY > L.TOTAL_RECEIVED_QTY 
   AND L.SERVICE_ID IS NULL 
   AND O.STATUS IN 
   (
      N'R',
      N'S',
      N'U',
      N'F',
      N'H' 
   )
   AND LINE_STATUS = N'A' 
UNION
SELECT
   L.PART_ID,  -- 1
   DW_Query_Section_ID = 4, -- 2
   [Status] = O.[STATUS],  -- 3
   REQUIRED_DATE = ISNULL ( ISNULL ( D.DESIRED_RECV_DATE, L.DESIRED_RECV_DATE ), CONVERT ( DATETIME, N'3999-12-31', 102 ) ), --
   Required_Qty = D.ORDER_QTY, --
   D.RECEIVED_QTY,  --
   D.ALLOCATED_QTY, --
   D.FULFILLED_QTY, --
   N'PD',  --
   O.ID,  --
   LTRIM ( STR ( L.LINE_NO, 22, 0 ) ),  --
   N'0',  --
   N'0',  --
   O.ORDER_DATE,  --
   D.DEL_SCHED_LINE_NO,  --
   rls_date = CONVERT ( DATETIME, DATENAME ( YY, O.PRINTED_DATE ) + N'-' + LEFT ( DATENAME ( MM, O.PRINTED_DATE ), 3 )
			 + N'-' + DATENAME ( DD, O.PRINTED_DATE ) ),  --
   WAREHOUSE_ID = ISNULL ( ISNULL ( D.WAREHOUSE_ID, L.WAREHOUSE_ID ), O.WAREHOUSE_ID ),  --
   L.WBS_CODE,  --
   L.SITE_ID,	--
   dsl_line_status = NULL,
   dsl_Line_Type = NULL,
   Lead_Time = P.PLANNING_LEADTIME,
   SafetyStock = NULL,

   Gross_Requirements = NULL,
   scheduled_Receipts = NULL,

   Planned_Order_Releases = NULL, 	
   Planned_Order_Release_Date = NULL,
   Projected_On_Hand = NULL,
   Net_Requirements = NULL,
   Planned_Order_Receipts = NULL,

	MRP_Side = null,
	MRP_LINE_CD = null,
	SortOrder = null,
	FLD1 = null,
	FLD2 = null,
	FLD3 = null,
	FLD4 = null,
	FLD5 = null

FROM
   PURC_ORDER_LINE L
   JOIN PURCHASE_ORDER O
   ON L.PURC_ORDER_ID = O.ID 
   JOIN PURC_LINE_DEL D 
   ON D.PURC_ORDER_ID = L.PURC_ORDER_ID 
   AND D.PURC_ORDER_LINE_NO = L.LINE_NO 
   JOIN PART P
   ON L.PART_ID = P.ID

   -- SELECT * FROM PURC_LINE_DEL D 

WHERE (1=1)
    
   -- AND L.PART_ID = @P4 
   and l.PART_ID IN (SELECT ID FROM PART)
   AND L.SITE_ID IN 
   (
      N'SK01' 
   )

   AND D.ORDER_QTY > ISNULL ( D.RECEIVED_QTY, 0 ) 
   AND L.SERVICE_ID IS NULL 
   AND O.STATUS IN 
   (
      N'R',
      N'S',
      N'U',
      N'F',
      N'H' 
   )
   AND LINE_STATUS = N'A' 
UNION
SELECT
	L.PART_ID,
	DW_Query_Section_ID = 5,  -- 5
   [Status] = I.STATUS,
   REQUIRED_DATE  = ISNULL ( I.DESIRED_RECV_DATE, CONVERT ( DATETIME, N'3999-12-31', 102 ) ),
   Required_Qty = L.ORDER_QTY,
   L.RECEIVED_QTY,
   Allocated_Qty = L.SUP_ALLOCATED_QTY,
   Fulfilled_Qty = L.SUP_FULFILLED_QTY,
   dsl_type = N'WH',  
   I.ID,
   LTRIM ( STR ( L.LINE_NO, 22, 0 ) ),
   N'',
   N'',
   I.DESIRED_SHIP_DATE,
   0,
   CONVERT ( DATETIME, N'3999-12-31', 102 ),
   I.TO_WHSE_ID,
   N'',
   W.SITE_ID,
   dsl_line_status = NULL,
   dsl_Line_Type = NULL,
   Lead_Time = P.PLANNING_LEADTIME,
   SafetyStock = NULL,

   Gross_Requirements = NULL,
   Scheduled_Receipts = NULL,

   Planned_Order_Releases = NULL, 	
   Planned_Order_Release_Date = NULL,
   
   Projected_On_Hand = NULL,
   Net_Requirements = NULL,
   Planned_Order_Receipts = NULL,

	MRP_Side = null,
	MRP_LINE_CD = null,
	SortOrder = null,
	FLD1 = null,
	FLD2 = null,
	FLD3 = null,
	FLD4 = null,
	FLD5 = null  
    
FROM
  -- Version 2
  [sql-lab-2].live.dbo.IBT I
   JOIN [sql-lab-2].live.dbo.IBT_LINE L
   ON I.ID = L.IBT_ID 
   JOIN [sql-lab-2].live.dbo.WAREHOUSE W 
   ON I.TO_WHSE_ID = W.ID
   JOIN PART P
   ON L.PART_ID = P.ID

WHERE (1=1)

   AND W.SITE_ID IN 
   (
      N'SK01' 
   )
   AND L.ORDER_QTY > L.RECEIVED_QTY 
   -- AND L.PART_ID = @P5 
   AND I.STATUS IN 
   (
      N'R',
      N'S',
      N'U',
      N'F',
      N'H' 
   )
   AND LINE_STATUS = N'A' 
UNION
SELECT
	PL.PART_ID,
	DW_Query_Section_ID = 6,  -- 6
   [Status] = LTRIM ( '' ),
   REQUIRED_DATE  = ISNULL ( PL.WANT_DATE, CONVERT ( DATETIME, N'3999-12-31', 102 ) ),
   Required_Qty = PL.ORDER_QTY,
   RECEIVED_QTY = 0,
   ALLOCATED_QTY = 0,
   FULFILLED_QTY = 0,
   [TYPE] = N'PL',
   dsl_base_id = PL.PART_ID,
   dsl_line = LTRIM ( STR ( PL.SEQ_NO, 22, 0 ) ),
   dsl_split_id = N'0',
   dsl_sub_id = N'0',
   CONVERT ( DATETIME, N'3999-12-31', 102 )  WANT_DATE,  -- open
   piece_no = 0,
   CONVERT ( DATETIME, N'3999-12-31', 102 ) RLS_DATE,
   WAREHOUSE_ID,
   WBS_CODE,
   PL.SITE_ID,
   dsl_line_status = 'Planned Order',
   dsl_Line_Type = 'S',
   Lead_Time = P.PLANNING_LEADTIME,
   SafetyStock = NULL,

   Gross_Requirements = NULL,
   Scheduled_Receipts = NULL,
   
   Planned_Order_Releases = NULL, 	
   Planned_Order_Release_Date = NULL,

   	Projected_On_Hand = NULL,
	Net_Requirements = NULL,
	Planned_Order_Receipts = NULL,

	MRP_Side = null,
	MRP_LINE_CD = null,
	SortOrder = null,
	FLD1 = null,
	FLD2 = null,
	FLD3 = null,
	FLD4 = null,
	FLD5 = null
   -- select * 
FROM
   [sql-lab-2].live.dbo.PLANNED_ORDER PL 
   -- Version 2
   INNER JOIN PART P
   ON PL.PART_ID = P.ID
WHERE (1=1)
   -- AND PL.PART_ID = @P6 
   AND PL.SITE_ID IN 
   (
      N'SK01' 
   )

UNION
	SELECT
	CP.PART_ID,
	DW_Query_Section_ID = 7,  -- 7
   [Status] = LTRIM ( '' ),
   REQUIRED_DATE  =ISNULL ( PL.WANT_DATE, CONVERT ( DATETIME, N'3999-12-31', 102 ) ),
   Required_Qty = PL.ORDER_QTY,
   0,
   0,
   0,
   N'PL',
   PL.PART_ID,
   LTRIM ( STR ( PL.SEQ_NO, 22, 0 ) ),
   N'0',
   N'0',
   CONVERT ( DATETIME, N'3999-12-31', 102 ),
   0,
   CONVERT ( DATETIME, N'3999-12-31', 102 ),
   PL.WAREHOUSE_ID,
   PL.WBS_CODE,
   PL.SITE_ID,
   dsl_line_status = 'Planned Order',
   dsl_Line_Type = 'S',
   Lead_Time = P.PLANNING_LEADTIME,
   SafetyStock = NULL,

   Gross_Requirements = NULL,
   Scheduled_Receipts = NULL,

   Planned_Order_Releases = NULL, 	
   Planned_Order_Release_Date = NULL,
   
   	Projected_On_Hand = NULL,
	Net_Requirements = NULL,
	Planned_Order_Receipts = NULL,

	MRP_Side = null,
	MRP_LINE_CD = null,
	SortOrder = null,
	FLD1 = null,
	FLD2 = null,
	FLD3 = null,
	FLD4 = null,
	FLD5 = null  
    
FROM
   [sql-lab-2].live.dbo.PLANNED_ORDER PL
   JOIN CO_PRODUCT CP
   ON CP.WORKORDER_BASE_ID = PL.PART_ID 
   JOIN PART_SITE PS 
   ON CP.WORKORDER_BASE_ID = PS.PART_ID 
   AND CP.WORKORDER_LOT_ID = PS.ENGINEERING_MSTR 
   JOIN PART P
   ON CP.PART_ID = P.ID

WHERE (1=1)
   -- AND CP.PART_ID = @P7 
   
   AND CP.WORKORDER_TYPE = N'M' 
   AND PS.SITE_ID IN 
   (
      N'SK01' 
   )


) AS X

ORDER BY
   2,
   4,
   11

-- -------------------------------------------------------------
 --X 20__resource planning MRP I ---------------------~~!
 --
 -- ------------------------------------------------------

 insert into #ResultsS (
 	[PART_ID]
	,[DW_Query_Section_ID]
	,[Status]
	,[REQUIRED_DATE]
	,[Required_Qty]
	,[Received_Qty]
	,[Allocated_Qty]
	,[Fulfilled_Qty]
	,[dsl_type]
	,[dsl_base_id]
	,[dsl_line]
	,[dsl_split_id]
	,[dsl_sub_id]
	,[DESIRED_RLS_DATE]
	,[piece_no]
	,[RLS_DATE]
	,[WAREHOUSE_ID]
	,[WBS_CODE]
	,[SITE_ID]

	,dsl_line_status
	,dsl_Line_Type 
	,Lead_Time 
	,SafetyStock 

	,Gross_Requirements 
	,Scheduled_Receipts 
	
	, Planned_Order_Releases 
	, Planned_Order_Release_Date

	,Projected_On_Hand
	,Net_Requirements
	,Planned_Order_Receipts

	,MRP_Side
	,MRP_LINE_CD
	,SortOrder
	,FLD1
	,FLD2
	,FLD3
	,FLD4
	,FLD5

	)
 SELECT
	[PART_ID]
	,[DW_Query_Section_ID]
	,[Status]
	,[REQUIRED_DATE]
	,[Required_Qty]
	,[Received_Qty]
	,[Allocated_Qty]
	,[Fulfilled_Qty]
	,[dsl_type]
	,[dsl_base_id]
	,[dsl_line]
	,[dsl_split_id]
	,[dsl_sub_id]
	,[DESIRED_RLS_DATE]
	,[piece_no]
	,[RLS_DATE]
	,[WAREHOUSE_ID]
	,[WBS_CODE]
	,[SITE_ID]

	,dsl_line_status = 
	CASE 
	WHEN dsl_type = 'P' then
      	'Scheduled receipts'
	WHEN dsl_type = 'W' then
	    'Scheduled receipts'
	WHEN dsl_type = 'WH' then  -- similar to on-order, open order, or scheduled order
      	'Scheduled receipts'
	WHEN dsl_type = 'PL' then
	    'Planned Order'
	ELSE
	    NULL
	END
	,dsl_Line_Type = 'S'
	,Lead_Time 
	,SafetyStock 

	,Gross_Requirements = NULL
	-- Side B of planned orders (rel)
	,Scheduled_Receipts = 
	CASE 
	WHEN dsl_type = 'P' then
      	[Required_Qty]
	WHEN dsl_type = 'WH' then  -- similar to on-order, open order, or scheduled order
      	[Required_Qty]
	WHEN dsl_type = 'W' then
	    [Required_Qty]
	ELSE
	    NULL
	END


	
	-- PL Release
	, Planned_Order_Releases = 
	CASE 
	WHEN dsl_type = 'PL' then
      	[Required_Qty]
	ELSE
	    NULL
	END

	, Planned_Order_Release_Date =
	CASE 
	WHEN dsl_type = 'PL' then
      	DATEADD(DAY,-Lead_Time, [REQUIRED_DATE])
	ELSE
	    NULL
	END

	,Projected_On_Hand
	,Net_Requirements
	,Planned_Order_Receipts

	,MRP_Side =
	CASE 
	WHEN dsl_type = 'PL' then
      	 'A'
	ELSE
	    NULL
	END

	-- Note: MRP Line Codes for Planned orders in Step 2 according to MRP_Side
	,MRP_LINE_CD = 
	CASE 
	WHEN dsl_type = 'P' then
      	'SCHE'
	WHEN dsl_type = 'W' then
	    'SCHE'
	WHEN dsl_type = 'WH' then  -- similar to on-order, open order, or scheduled order
      	'SCHE'
	ELSE
	    NULL
	END

	-- 2nd pass fields
	,SortOrder = null
	,FLD1 = null
	,FLD2 = null
	,FLD3 = null
	,FLD4 = null
	,FLD5 = null

FROM #supply		

--X 21__Create MRP Table Ends ---------------------~~!

--select * from #ResultsS
--where (1=1)
----and dsl_line_status = 'Planned Order'
--and dsl_line_status = 'Scheduled Receipts'
--and status = 'R'
----and required_date > '2020-05-04'
----and Planned_Order_Release_Date > '2020-01-01'
--and DESIRED_RLS_DATE > '2020-05-04' 
--and DESIRED_RLS_DATE < '2020-05-06' 
--and DW_Query_Section_ID = 1

--X ~~
-- ** pl **
select 
  
	 r.PART_ID
	,r.DW_Query_Section_ID
	,r.Status
	,r.REQUIRED_DATE 
	,r.Required_Qty
	,r.Received_Qty
	,r.Allocated_Qty
	,r.Fulfilled_Qty
	,r.dsl_type
	,r.dsl_base_id
	,r.dsl_line
	,r.dsl_split_id
	,r.dsl_sub_id
	,r.DESIRED_RLS_DATE
	,r.piece_no
	,r.RLS_DATE
	,r.WAREHOUSE_ID
	,r.WBS_CODE
	,r.SITE_ID
	,r.dsl_line_status
	,r.dsl_Line_Type
	,r.Lead_Time
	,r.SafetyStock
	,r.Gross_Requirements
	,r.Scheduled_Receipts
	,r.Planned_Order_Releases
	,r.Planned_Order_Release_Date
	,r.Projected_On_Hand
	,r.Net_Requirements
	,r.Planned_Order_Receipts
	,r.MRP_Side
	,r.MRP_Line_CD
	,r.SortOrder
	,r.FLD1
	,r.FLD2
	,r.FLD3
	,r.FLD4
	,r.FLD5

  ,p.COMMODITY_CODE
  ,p.PLANNER_USER_ID
  ,Release_Late_Days = iif(r.Planned_Order_Release_Date < convert(date,getdate()), (datediff(day,getdate(),r.Planned_Order_Release_Date)) * -1,null)
	,p.FABRICATED
	,p.PURCHASED
-- SUPPLY SUPPLY SUPPLY SUPPLY SUPPLY SUPPLY SUPPLY SUPPLY -------------------------------
-- ~~
  into #supplySet
  -- select *
  ----distinct dw_query_section_id
from #ResultsS r
join part p
on r.part_id = p.id
where (1=1)
AND dsl_type != 'PL'
--and dsl_line_status = 'Planned Order'
--and dsl_line_status = 'Scheduled Receipts'
--and status = 'R'
--and required_date > '2020-05-04'
--and Planned_Order_Release_Date > '2020-01-01'
--and DESIRED_RLS_DATE > '2020-05-04' 
--and DESIRED_RLS_DATE < '2021-05-06' 
--and DW_Query_Section_ID = 1
and (part_id = @part_id
  or @part_id is null)
--,'70507P-2000 X 6.40 X 6.60'
--,'20243C-050 12 X 48'
--,'70750E-3100073'
--,'74A501729-2012'
--,'151W0231-24'
--)

ORDER BY Planned_Order_Release_Date

--SELECT   * FROM #supplySet
-- SUPPLY SUPPLY SUPPLY SUPPLY SUPPLY SUPPLY SUPPLY SUPPLY -////////////////////////////////
-- SELECT   * FROM #demandSet

/**********************************************************************************************
Description:   demsand	
Sample:			

Date        Modified By         Change Description
----------  ------------------  ------------------------------------------------------------



**********************************************************************************************/


-- C:\SQL\CodeCompare-1\part1-1.sql
-- C:\SQL\CodeCompare-1\part1-1 Demand.sql
-- C:\SQL\CodeCompare-1\part1-1 Demand - All.sql
-- C:\SQL\Uber Query\1.4 MPS\001_Demand\005.1 Demand - Planned Receipts\005.1 Demand - Planned Receipts.sql
-- C:\SQL\Uber Query\2.1 Outlined Uber Query\2.2 Purchase Order\Purchasing Planned Order Queue.1 Demand.sql

/**********************************************************************************************
Description:	310 - planned order]- demand
Sample:			

Date        Modified By         Change Description
----------  ------------------  ------------------------------------------------------------


TESTER:  !!! THERE'S NO ORDER ID PEGGED WITHIN THIS QUERY BUT THE REPORT HAS THE ORDER PEGGED
!!! There's no quantity required !!
100t1430-87 HAS C 536956/1 457285/1, 457286/1, 457288/1

see also - 311 - planned orders- supply
**********************************************************************************************/


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

-- drop table #demand
IF OBJECT_ID('tempdb..#results') IS NOT NULL DROP TABLE #results

IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1
IF OBJECT_ID('tempdb..#temp2') IS NOT NULL DROP TABLE #temp2
IF OBJECT_ID('tempdb..#temp3') IS NOT NULL DROP TABLE #temp3
IF OBJECT_ID('tempdb..#temp4') IS NOT NULL DROP TABLE #temp4
IF OBJECT_ID('tempdb..#temp5') IS NOT NULL DROP TABLE #temp5


--declare @part_id nvarchar(255) = '74A588133-2009'   --'151W0231-3'   -- '151W0231-3'  -- 151W0231-2 -- '100T1430-87' -- 151W0231-24  -- 6AL4VE-1278 -- '151W0231-2'

--declare
-- @P1 NVARCHAR(255) = @part_id
--,@P2 NVARCHAR(255) = @part_id
--,@P3 NVARCHAR(255) = @part_id
--,@P4 NVARCHAR(255) = @part_id
--,@P5 NVARCHAR(255) = @part_id
--,@P6 NVARCHAR(255) = @part_id
--,@P7 NVARCHAR(255) = @part_id

SELECT
  *
  into #results
FROM (
	SELECT
	   dbBomName = NULL,
	   R.PART_ID,  --1
	   DW_Query_Section_ID = 1,  -- 2
	   R.[STATUS],
	   REQUIRED_DATE =ISNULL ( R.REQUIRED_DATE, CONVERT ( DATETIME, N'3999-12-31', 102 ) ),
	   R.CALC_QTY,
	   R.ISSUED_QTY,
	   R.ALLOCATED_QTY,
	   R.FULFILLED_QTY,
	   DSL_TYPE  = R.WORKORDER_TYPE,
	   DSL_BASE_ID = R.WORKORDER_BASE_ID,
	   DSL_line = R.WORKORDER_LOT_ID,
	   DSL_SPLIT_ID = R.WORKORDER_SPLIT_ID,
	   DSL_sub_id = R.WORKORDER_SUB_ID,
	   R.OPERATION_SEQ_NO,
	   R.PIECE_NO,
	   R.WAREHOUSE_ID,
	   REQ_NO = 0,
	   R.WBS_CODE,
	   dsl_line_status = N'D',
	   dsl_Line_Type =  N'D',
	   W.SITE_ID ,
	   Lead_Time = NULL,
	   SafetyStock = NULL


-- select * from Requirement where part_id = '6AL4VE-1278'
	FROM
	   REQUIREMENT R,
	   WORK_ORDER W 
	WHERE (1=1)
	  -- AND R.PART_ID = @P1 
	   AND R.WORKORDER_TYPE = N'W' 
	   AND R.WORKORDER_TYPE = W.TYPE 
	   AND R.WORKORDER_BASE_ID = W.BASE_ID 
	   AND R.WORKORDER_LOT_ID = W.LOT_ID 
	   AND R.WORKORDER_SPLIT_ID = W.SPLIT_ID 
	   AND W.SUB_ID = N'0' 
	   AND W.SITE_ID IN 
	   (
		  N'SK01' 
	   )
	   AND R.CALC_QTY > R.ISSUED_QTY 
	   AND R.SUBORD_WO_SUB_ID IS NULL 
	   AND R.STATUS IN 
	   (
		  N'R',
		  N'S',
		  N'U',
		  N'F' 
	   )
	UNION
	SELECT
	   dbBomName = NULL,
	   LN.PART_ID,
	   DW_Query_Section_ID = 2,
	   CO.STATUS,
	   REQUIRED_DATE =  ISNULL ( ISNULL ( LN.DESIRED_SHIP_DATE, CO.DESIRED_SHIP_DATE ), CONVERT ( DATETIME, N'3999-12-31', 102 ) ),

	   LN.ORDER_QTY,
	   LN.TOTAL_SHIPPED_QTY,
	   LN.ALLOCATED_QTY,
	   FULFILLED_QTY = LN.FULFILLED_QTY,
	   DSL_TYPE = N'C',


	   DSL_BASE_ID = LN.CUST_ORDER_ID,
	   DSL_line = LTRIM ( STR ( LN.LINE_NO, 22, 0 ) ),
	   DSL_SPLIT_ID = N'0',
	   DSL_sub_id = N'0',
	   OPERATION_SEQ_NO = 0,

	   PIECE_NO = 0,
	   WAREHOUSE_ID = ISNULL ( LN.WAREHOUSE_ID, CO.WAREHOUSE_ID ),
	   REQ_NO = 0,
	   LN.WBS_CODE,
	   dsl_line_status = ISNULL ( LN.LINE_STATUS, N'A' ),
	   dsl_Line_Type = N'D',
	   LN.SITE_ID, 
	   Lead_Time = NULL,
	   SafetyStock = NULL
	FROM
	   CUST_ORDER_LINE LN,
	   CUSTOMER_ORDER CO 
	WHERE (1=1)
	   AND LN.CUST_ORDER_ID = CO.ID 
	   AND LN.PART_ID IN( SELECT ID FROM PART) 
	   AND LN.SITE_ID IN 
	   (
		  N'SK01' 
	   )
	   AND LN.ORDER_QTY > LN.TOTAL_SHIPPED_QTY 
	   AND NOT EXISTS 
	   (
		  SELECT
			 CLD.CUST_ORDER_ID 
		  FROM
			 CUST_LINE_DEL CLD 
		  WHERE
			 CLD.CUST_ORDER_ID = LN.CUST_ORDER_ID 
			 AND CLD.CUST_ORDER_LINE_NO = LN.LINE_NO 
	   )
	   AND STATUS IN 
	   (
		  N'R',
		  N'S',
		  N'U',
		  N'F' 
	   )
	   AND LN.LINE_STATUS = N'A' 
	UNION
	SELECT
	   dbBomName = NULL,
	   LN.PART_ID,
	   DW_Query_Section_ID = 3,
	   CO.STATUS,
	   REQUIRED_DATE = ISNULL ( ISNULL ( D.DESIRED_SHIP_DATE, LN.DESIRED_SHIP_DATE ), CONVERT ( DATETIME, N'3999-12-31', 102 ) ),
	   D.ORDER_QTY,
	   ISNULL ( D.SHIPPED_QTY, 0 ),
	   D.ALLOCATED_QTY,
	   D.FULFILLED_QTY,
	   N'CD',
	   LN.CUST_ORDER_ID,
	   LTRIM ( STR ( LN.LINE_NO, 22, 0 ) ),
	   N'0',
	   N'0',
	   0,
	   D.DEL_SCHED_LINE_NO,
	   ISNULL ( ISNULL ( D.WAREHOUSE_ID, LN.WAREHOUSE_ID ), CO.WAREHOUSE_ID ),
	   REQ_NO = 0,
	   LN.WBS_CODE,
	   ISNULL ( LN.LINE_STATUS, N'A' ),
	   ISNULL ( D.LINE_STATUS, N'A' ),
	   LN.SITE_ID ,
	   Lead_Time = NULL,
	   SafetyStock = NULL
	FROM
	   CUST_ORDER_LINE LN,
	   CUSTOMER_ORDER CO,
	   CUST_LINE_DEL D 
	WHERE (1=1)
	   AND LN.CUST_ORDER_ID = CO.ID 
	   AND LN.CUST_ORDER_ID = D.CUST_ORDER_ID 
	   AND LN.LINE_NO = D.CUST_ORDER_LINE_NO 
	 --  AND LN.PART_ID = @P3 
	   AND LN.SITE_ID IN 
	   (
		  N'SK01' 
	   )
	   AND D.ORDER_QTY > ISNULL ( D.SHIPPED_QTY, 0 ) 
	   AND STATUS IN 
	   (
		  N'R',
		  N'S',
		  N'U',
		  N'F' 
	   )
	   AND LN.LINE_STATUS = N'A' 
	   AND 
	   (
		  D.LINE_STATUS <> N'C' 
		  OR D.LINE_STATUS IS NULL 
	   )
	UNION

	SELECT
	   dbBomName = NULL,
	   LN.PART_ID,
	   DW_Query_Section_ID = 4,
	   I.STATUS,
	   REQUIRED_DATE = ISNULL ( I.DESIRED_SHIP_DATE, CONVERT ( DATETIME, N'3999-12-31', 102 ) ),
	   LN.ORDER_QTY,
	   LN.SHIPPED_QTY,
	   LN.DEM_ALLOCATED_QTY,
	   LN.DEM_FULFILLED_QTY,
	   N'WH',
	   I.ID,
	   LTRIM ( STR ( LN.LINE_NO, 22, 0 ) ),
	   LTRIM ( '' ),
	   LTRIM ( '' ),
	   0,
	   0,
	   I.FROM_WHSE_ID,
	   REQ_NO = 0,
	   N'',
	   ISNULL ( LN.LINE_STATUS, N'A' ),
	   N'D',
	   W.SITE_ID,
	   Lead_Time = NULL,
	   SafetyStock = NULL 
	FROM
	   [sql-lab-2].live.dbo.IBT I,
	   [sql-lab-2].live.dbo.IBT_LINE LN,
	   [sql-lab-2].live.dbo.WAREHOUSE W 
	WHERE  (1=1)
	   AND I.ID = LN.IBT_ID 
	   AND I.FROM_WHSE_ID = W.ID 
	   AND W.SITE_ID IN 
	   (
		  N'SK01' 
	   )
	   AND 
	   (
		  LN.ORDER_QTY > LN.SHIPPED_QTY 
		  OR LN.SHIPPED_QTY IS NULL 
	   )
	  -- AND LN.PART_ID = @P4 
	   AND STATUS IN 
	   (
		  N'R',
		  N'S',
		  N'U',
		  N'F' 
	   )
	   AND LN.LINE_STATUS = N'A' 
	UNION

	 SELECT
	   dbBomName = PR.PARENT_PART_ID,
	   PR.REQUIRED_PART_ID PART_ID,
	   DW_Query_Section_ID = 5,
	   LTRIM ( 'P' ),
	   REQUIRED_DATE = ISNULL ( PR.REQUIRED_DATE, CONVERT ( DATETIME, N'3999-12-31', 102 ) ),
	   PR.REQUIRED_QTY,
	   0,
	   0,
	   0,
	   N'PL',
	   PR.PARENT_PART_ID,
	   LTRIM ( STR ( PR.PARENT_SEQ_NO, 22, 0 ) ),
	   N'0',
	   N'0',
	   0,
	   0,
	   PR.WAREHOUSE_ID,
	   PR.REQ_NO,
	   N'',
	   N'D',
	   N'D',
	   PL.SITE_ID ,
   	   Lead_Time = NULL,
	   SafetyStock = NULL
	FROM
	   PLANNED_MATL_REQ PR,
	   [sql-lab-2].live.dbo.PLANNED_ORDER PL 
	WHERE (1=1)
	   AND PR.PARENT_PART_ID = PL.PART_ID 
	   AND PR.PARENT_SEQ_NO = PL.SEQ_NO 
	   AND PR.SITE_ID = PL.SITE_ID 
	   AND PL.SITE_ID IN 
	   (
		  N'SK01' 
	   )


	) AS X
ORDER BY
	   2,
	   4


select 
-- select distinct dsl_line_status
	 r.dbBomName
	,r.PART_ID
	,r.DW_Query_Section_ID
	,r.STATUS
	,r.REQUIRED_DATE
	,r.CALC_QTY
	,r.ISSUED_QTY
	,r.ALLOCATED_QTY
	,r.FULFILLED_QTY
	,r.DSL_TYPE
	,r.DSL_BASE_ID
	,r.DSL_line
	,r.DSL_SPLIT_ID
	,r.DSL_sub_id
	,r.OPERATION_SEQ_NO
	,r.PIECE_NO
	,r.WAREHOUSE_ID
	,r.REQ_NO
	,r.WBS_CODE
	,r.dsl_line_status
	,r.dsl_Line_Type
	,r.SITE_ID
	,r.Lead_Time
    ,r.SafetyStock

	,p.COMMODITY_CODE
	,p.PLANNER_USER_ID
	,Release_Late_Days = null  -- applicable to supply but not demand
	,p.FABRICATED
	,p.PURCHASED
-- DEMAND DEMAND DEMAND DEMAND DEMAND DEMAND -----------------------
  -- select *
  INTO #demandset
from #results r
join part p
on r.part_id = p.id
where (1=1)
AND r.dsl_type = 'PL'
and 
(part_id = @part_id
or @part_id is null)

--,'70507P-2000 X 6.40 X 6.60'
--,'20243C-050 12 X 48'
--,'70750E-3100073'
--,'74A501729-2012'
--,'151W0231-24'
--,'6AL4VE-1278'
--)

-- 

----select * 
----from #demand_set d

-- DEMAND DEMAND DEMAND DEMAND DEMAND DEMAND -----/////////////////////////////

-- REPORT REPORT REPORT REPORT REPORT REPORT ------------------------------------
-- ~~
SELECT
	--dataDateTime = GETDATE()
	 Order_ID = x.dsl_type + ' ' + x.part_id + '/' + X.dsl_line
	,x.required_date Due_Date
	,x.Planned_Order_Release_Date Rls_Date
	,X.dsl_type
	,Net_Qty_Due = sum(x.Net_Qty_Due)
	--,x.dbBomName
	,x.COMMODITY_CODE
	,x.PLANNER_USER_ID
	,x.Release_Late_Days   -- applicable to supply but not demand
	,x.FABRICATED
	,x.PURCHASED
	--,x.dsl_base_id
	,x.[Status] Stat
	,Peg_To = x.dsl_type + ' ' + x.DSL_BASE_ID
	,PART_ID
FROM (
SELECT 
      s.part_id
	, s.required_date
	, s.Planned_Order_Release_Date
	, s.dsl_type
	, s.Required_Qty As Net_Qty_Due
	,dbBomName = null
	,S.COMMODITY_CODE
	,s.PLANNER_USER_ID
	,s.Release_Late_Days   -- applicable to supply but not demand
	,s.FABRICATED
	,s.PURCHASED
	,status = iif(s.dsl_type = 'Pl', 'P', s.Status)
	,s.dsl_line
	,DSL_BASE_ID = null
from #supplyset s

) AS X
WHERE (X.COMMODITY_CODE = @COMMODITY_CODE
      OR @COMMODITY_CODE IS NULL)

group by
	 x.part_id 
	 , X.dsl_line
	,x.required_date 
	,X.Planned_Order_Release_Date
	,X.dsl_type
	--,x.Net_Qty_Due
	--,x.dbBomName
	,x.COMMODITY_CODE
	,x.PLANNER_USER_ID
	,x.Release_Late_Days   -- applicable to supply but not demand
	,x.FABRICATED
	,x.PURCHASED
	,x.[Status]

	,x.dsl_type  
	--,x.DSL_BASE_ID
order by x.PART_ID,x.required_Date

-- drop table #supplySet
-- select * from #demandSet
-- select * from #supplyset where part_id = '2-162-N70'
-- REPORT REPORT REPORT REPORT REPORT REPORT ------------------------------------
-- Exec Report.usp_Report_Purchasing_Order_Queue
GO


