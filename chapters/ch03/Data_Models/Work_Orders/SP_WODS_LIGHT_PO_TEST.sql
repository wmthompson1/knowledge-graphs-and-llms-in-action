
IF OBJECT_ID(N'tempdb..#schema_results') IS NOT NULL DROP TABLE #schema_results;

CREATE TABLE #schema_results (
    [start_date] datetime NULL,
    [CLOSE_DATE] datetime NULL,
    [DESIRED_WANT_DATE] datetime NULL,
    [EXP/FLT] nvarchar(254) NULL,
    [BASE_ID] nvarchar(30) NOT NULL,
    [LOT_ID] nvarchar(3) NOT NULL,
    [SPLIT_ID] nvarchar(3) NOT NULL,
    [SUB_ID] nvarchar(3) NOT NULL,
    [TYPE] nchar(1) NOT NULL,
    [PART_ID] nvarchar(30) NULL,
    [DESIRED_QTY] decimal(20,8) NULL,
    [STATUS] nchar(1) NOT NULL,
    [CUSTOMER_ORDER] nvarchar(15) NULL,
    [LINE_NO] smallint NULL,
    [CUSTOMER_ID2] nvarchar(20) NULL,
    [CUSTOMER_ID] nvarchar(20) NULL,
    [parentPart] nvarchar(30) NULL,
    [EndItem_Part_id] nvarchar(30) NULL,
    [EndItem_Buyer_User_ID] nvarchar(20) NULL,
    [Allocation_Type] nvarchar(8) NULL,
    [buyer_ptr] nvarchar(1) NULL,
    [CurrentOperation] int NULL,
    [StatusCurrOp] smallint NULL,
    [RESOURCE_ID] nvarchar(15) NULL,
    [PRINTED_DATE] datetime NULL,
    [CREATE_DATE] datetime NOT NULL,
    [remaining_operations] nvarchar(MAX) NOT NULL,
    [QTY_ON_HAND] decimal(20,8) NULL,
    [QTY_IN_DEMAND] decimal(20,8) NULL,
    [BUYER_USER_ID] nvarchar(20) NULL,
    [PLANNER_USER_ID] nvarchar(20) NULL,
    [COMMODITY_CODE] nvarchar(15) NULL,
    [DESCRIPTION] nvarchar(120) NULL,
    [USER_10] nvarchar(80) NULL,
    [col_user_1] nvarchar(80) NULL,
    [RWPart] nvarchar(30) NULL,
    [Report_Part] nvarchar(30) NULL,
    [CUSTOMER_PO_REF] nvarchar(40) NULL,
    [WORK_ORDER_NOTES] nvarchar(MAX) NULL,
    [CUST_ORD_CREATEDATE] datetime NULL,
    [PartMaterialType] nvarchar(254) NOT NULL,
    [Alloy] nvarchar(254) NOT NULL,
    [MaterialType] nvarchar(509) NOT NULL,
    [CO_AMOUNT] decimal(23,8) NULL,
    [UNIT_PRICE] decimal(22,8) NULL,
    [TOTAL_AMT_SHIPPED] decimal(23,8) NULL,
    [COL_AMOUNT] decimal(23,8) NULL,
    [TimeLimit] int NULL
);



DECLARE @BaseId nvarchar(50) = N'1817652';
DECLARE @LotId  nvarchar(3)  = N'1';
DECLARE @SubId  nvarchar(3)  = N'1';

-- Keep the #schema_results definition here, matching the procedure's output.



INSERT INTO #schema_results
EXEC dbo.SP_WODS_Light_PO
    @BASE_ID = @BaseId,
    @LOT_ID  = @LotId,
    @SUB_ID  = @SubId;

select * from #schema_results;