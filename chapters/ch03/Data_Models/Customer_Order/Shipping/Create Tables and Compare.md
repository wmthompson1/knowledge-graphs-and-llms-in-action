## problem
TRUNCATE TABLE  LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT

INSERT INTO LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT

SELECT A.*, CL.USER_6, 'LIVE' 
FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT A WITH (NOLOCK)
LEFT JOIN LIVE.dbo.CUST_ORDER_LINE CL WITH (NOLOCK) ON A.CUST_ORDER_ID = CL.CUST_ORDER_ID 
	AND A.COL_LINE_NO = CL.LINE_NO
WHERE A.FILTER_DATE >= '2024-12-24' --and a.CUST_ORDER_ID = '498033' order by a.COL_LINE_NO

/* Error */
Msg 213, Level 16, State 1, Procedure sp_Shipments_Core_Feed_01, Line 543 [Batch Start Line 12]
Column name or number of supplied values does not match table definition.

## Resolve
Compare Create Feed_01_Core_Intermediate_complement_OT to
Create for My_Derived_Table

Create Feed_01_Core_Intermediate_complement_OT

USE [LIVESupplemental]
GO

/****** Object:  Table [dbo].[Feed_01_Core_Intermediate_complement_OT]    Script Date: 7/31/2026 8:56:20 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Feed_01_Core_Intermediate_complement_OT](
	[CTE] [nvarchar](10) NULL,
	[CUSTOMER_ID] [nvarchar](40) NULL,
	[CUST_ORDER_ID] [nvarchar](80) NULL,
	[COL_LINE_NO] [nvarchar](5) NULL,
	[ORDER_DATE] [datetime] NULL,
	[CREATE_DATE] [datetime] NULL,
	[DESIRED_SHIP_DATE] [datetime] NULL,
	[FILTER_CASE] [nvarchar](80) NULL,
	[FILTER_DATE] [date] NULL,
	[CO_STATUS] [nvarchar](5) NULL,
	[UPDATE_USING_MISC_REF] [nvarchar](80) NULL,
	[SERVICE_CHARGE_ID] [nvarchar](80) NULL,
	[LINE_TYPE] [nvarchar](80) NULL,
	[LINE_ITEM] [nvarchar](80) NULL,
	[CHARGE_TYPE] [nvarchar](80) NULL,
	[CUST_PART_DESC] [nvarchar](max) NULL,
	[COL_PARTID] [nvarchar](80) NULL,
	[P2ID] [nvarchar](80) NULL,
	[PART_ID] [nvarchar](80) NULL,
	[DESCRIPTION] [nvarchar](100) NULL,
	[PART_PROD_CODE] [nvarchar](5) NULL,
	[PART_COMM_CODE] [nvarchar](20) NULL,
	[PLANNER_USER_ID] [nvarchar](50) NULL,
	[BUYER_USER_ID] [nvarchar](50) NULL,
	[REASONING] [int] NULL,
	[SHIP_SHORT] [nvarchar](5) NULL,
	[ORDER_QTY] [float] NULL,
	[TOTAL_SHIPPED_QTY] [float] NULL,
	[REMQTY] [float] NULL,
	[UNSHIPPEDQTY] [float] NULL,
	[UNIT_PRICE] [decimal](18, 0) NULL,
	[BUS_STREAM] [nvarchar](20) NULL,
	[MATERIAL_TYPE] [nvarchar](50) NULL,
	[PACKLIST_ID] [nvarchar](20) NULL,
	[PACKLIST_LINE_NO] [nvarchar](5) NULL,
	[SHIPPED_QTY] [float] NULL,
	[SHIPPED_DATE] [datetime] NULL,
	[INVOICE_DATE] [datetime] NULL,
	[INVOICE_ID] [nvarchar](20) NULL,
	[INVOICE_LINE] [nvarchar](5) NULL,
	[INVOICE_AMT] [decimal](18, 0) NULL,
	[INVOICE_QTY] [float] NULL,
	[SHIPPED_AMOUNT] [decimal](18, 0) NULL,
	[UNSHIPPED_AMOUNT] [decimal](18, 0) NULL,
	[ADJUSTED_DUE_DATE] [datetime] NULL,
	[SUPPLY_TYPE] [nvarchar](5) NULL,
	[BASE_ID] [nvarchar](80) NULL,
	[LOT_ID] [nvarchar](6) NULL,
	[SPLIT_ID] [nvarchar](6) NULL,
	[SUB_ID] [nvarchar](6) NULL,
	[ORDER_STATUS] [nvarchar](20) NULL,
	[MFG_COUNT] [int] NULL,
	[FIN_COUNT] [int] NULL,
	[O_COUNT] [int] NULL,
	[NULL_COUNT] [int] NULL,
	[UPD_BUS_STREAM] [nvarchar](20) NULL,
	[FILTER_PERIOD] [datetime] NULL,
	[TARGET_GOALS] [float] NULL,
	[DESIRED_RLS_DATE] [datetime] NULL,
	[CO_DESIRED_SHIP_DATE] [datetime] NULL,
	[ON_TIME1] [int] NULL,
	[LATE1] [int] NULL,
	[On Time?] [varchar](30) NULL,
	[TOTAL QTY] [int] NULL,
	[LATE] [int] NULL,
	[ON TIME] [int] NULL,
	[Start of Month] [date] NULL,
	[UnshippedAmount_Backlog] [decimal](18, 2) NULL,
	[Total_Backlog] [decimal](18, 2) NULL,
	[RowID] [int] NULL,
	[COL_UDF6] [varchar](80) NULL,
	[BASE_TABLE] [varchar](24) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

# Create for My_Derived_Table


