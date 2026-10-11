SET XACT_ABORT ON;

DECLARE   
    @TotalRows        INT,
    @DeletedRows      INT,
    @MaxDeleteAllowed INT;

SELECT @TotalRows = COUNT(*) 
FROM [dbo].[WODS_Comp_test223];

SET @MaxDeleteAllowed = CEILING(@TotalRows * 0.10);

DECLARE @MergeOutput TABLE
(
    ActionType NVARCHAR(10),
    KeyValue   NVARCHAR(4000)
);

BEGIN TRANSACTION;

MERGE [dbo].[WODS_Comp_test223] AS trgt
USING [dbo].[WODS_Comp_test223] AS src
    ON trgt.[WONUM] = src.[WONUM]

-- ==========================================
-- WHEN MATCHED (ONLY WHEN CHANGED)
-- ==========================================
WHEN MATCHED AND
(
    ISNULL(trgt.[start_date], '19000101') <> ISNULL(src.[start_date], '19000101')
    OR ISNULL(trgt.[CLOSE_DATE], '19000101') <> ISNULL(src.[CLOSE_DATE], '19000101')
    OR ISNULL(trgt.[DESIRED_WANT_DATE], '19000101') <> ISNULL(src.[DESIRED_WANT_DATE], '19000101')
    OR ISNULL(trgt.[EXP/FLT], '') <> ISNULL(src.[EXP/FLT], '')
    OR ISNULL(trgt.[BASE_ID], '') <> ISNULL(src.[BASE_ID], '')
    OR ISNULL(trgt.[LOT_ID], '') <> ISNULL(src.[LOT_ID], '')
    OR ISNULL(trgt.[SPLIT_ID], '') <> ISNULL(src.[SPLIT_ID], '')
    OR ISNULL(trgt.[SUB_ID], '') <> ISNULL(src.[SUB_ID], '')
    OR ISNULL(trgt.[TYPE], '') <> ISNULL(src.[TYPE], '')
    OR ISNULL(trgt.[PART_ID], '') <> ISNULL(src.[PART_ID], '')
    OR ISNULL(trgt.[DESIRED_QTY], -999999) <> ISNULL(src.[DESIRED_QTY], -999999)
    OR ISNULL(trgt.[STATUS], '') <> ISNULL(src.[STATUS], '')
    OR ISNULL(trgt.[CUSTOMER_ORDER], '') <> ISNULL(src.[CUSTOMER_ORDER], '')
    OR ISNULL(trgt.[LINE_NO], -999999) <> ISNULL(src.[LINE_NO], -999999)
    OR ISNULL(trgt.[CUSTOMER_ID2], '') <> ISNULL(src.[CUSTOMER_ID2], '')
    OR ISNULL(trgt.[CUSTOMER_ID], '') <> ISNULL(src.[CUSTOMER_ID], '')
    OR ISNULL(trgt.[EndItem_Part_id], '') <> ISNULL(src.[EndItem_Part_id], '')
    OR ISNULL(trgt.[EndItem_Buyer_User_ID], '') <> ISNULL(src.[EndItem_Buyer_User_ID], '')
    OR ISNULL(trgt.[Allocation_Type], '') <> ISNULL(src.[Allocation_Type], '')
    OR ISNULL(trgt.[buyer_ptr], '') <> ISNULL(src.[buyer_ptr], '')
    OR ISNULL(trgt.[CurrentOperation], -999999) <> ISNULL(src.[CurrentOperation], -999999)
    OR ISNULL(trgt.[StatusCurrOp], -999999) <> ISNULL(src.[StatusCurrOp], -999999)
    OR ISNULL(trgt.[RESOURCE_ID], '') <> ISNULL(src.[RESOURCE_ID], '')
    OR ISNULL(trgt.[PRINTED_DATE], '19000101') <> ISNULL(src.[PRINTED_DATE], '19000101')
    OR ISNULL(trgt.[CREATE_DATE], '19000101') <> ISNULL(src.[CREATE_DATE], '19000101')
    OR ISNULL(trgt.[remaining_operations], '') <> ISNULL(src.[remaining_operations], '')
    OR ISNULL(trgt.[QTY_ON_HAND], -999999) <> ISNULL(src.[QTY_ON_HAND], -999999)
    OR ISNULL(trgt.[QTY_IN_DEMAND], -999999) <> ISNULL(src.[QTY_IN_DEMAND], -999999)
    OR ISNULL(trgt.[BUYER_USER_ID], '') <> ISNULL(src.[BUYER_USER_ID], '')
    OR ISNULL(trgt.[PLANNER_USER_ID], '') <> ISNULL(src.[PLANNER_USER_ID], '')
    OR ISNULL(trgt.[COMMODITY_CODE], '') <> ISNULL(src.[COMMODITY_CODE], '')
    OR ISNULL(trgt.[DESCRIPTION], '') <> ISNULL(src.[DESCRIPTION], '')
    OR ISNULL(trgt.[USER_10], '') <> ISNULL(src.[USER_10], '')
    OR ISNULL(trgt.[col_user_1], '') <> ISNULL(src.[col_user_1], '')
    OR ISNULL(trgt.[RWPart], '') <> ISNULL(src.[RWPart], '')
    OR ISNULL(trgt.[Report_Part], '') <> ISNULL(src.[Report_Part], '')
    OR ISNULL(trgt.[CUSTOMER_PO_REF], '') <> ISNULL(src.[CUSTOMER_PO_REF], '')
    OR ISNULL(trgt.[WORK_ORDER_NOTES], '') <> ISNULL(src.[WORK_ORDER_NOTES], '')
    OR ISNULL(trgt.[CUST_ORD_CREATEDATE], '19000101') <> ISNULL(src.[CUST_ORD_CREATEDATE], '19000101')
    OR ISNULL(trgt.[PartMaterialType], '') <> ISNULL(src.[PartMaterialType], '')
    OR ISNULL(trgt.[Alloy], '') <> ISNULL(src.[Alloy], '')
    OR ISNULL(trgt.[MaterialType], '') <> ISNULL(src.[MaterialType], '')
    OR ISNULL(trgt.[CO_AMOUNT], -999999) <> ISNULL(src.[CO_AMOUNT], -999999)
    OR ISNULL(trgt.[UNIT_PRICE], -999999) <> ISNULL(src.[UNIT_PRICE], -999999)
    OR ISNULL(trgt.[TOTAL_AMT_SHIPPED], -9