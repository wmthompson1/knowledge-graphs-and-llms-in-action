use staging;
--use live;
go



/**********************************************************************************************
Description: SP_MERGE_WODS_LIGHT
Sample:
sql agent: 
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
06/03/2026 williamt			created
06/03/2026 williamt			add two new fields to merge, integration: the two datasets needs to be added to wods feed
06/11/2026 williamt			added directional gate to prevent excessive deletes, added comments for clarity

-- SP_MERGE_WODS_LIGHT.sql
-- select * from Staging.[dbo].[WODS_Comp_test223] 
-- drop procedure dbo.SP_MERGE_WODS_LIGHT

1. report procedure sp_Customer_Order_Master on live

2. EXEC ('staging.dbo.SP_MERGE_WODS_LIGHT');
  - then the sp_MERGE_WODS_LIGHT procedure merges the WODS feed with the existing WODS_Comp_test223 table in
   staging to create an updated WODS feed with the two new fields of desired want date and production status.  
   This updated feed is then used in the sp_Customer_Order_Master procedure to pull in the WODS information for 
   the customer order lines.
    - Runs select from staging.dbo.WODS_Comp_test223 which is the updated WODS feed with the two new fields of 
    desired want date and production status.

EXEC ('Live.dbo.SP_WODS_Light');
EXEC ('staging.dbo.SP_MERGE_WODS_LIGHT');
**********************************************************************************************/



CREATE OR ALTER procedure dbo.SP_MERGE_WODS_LIGHT
as

SET XACT_ABORT ON;

DECLARE   
    @TotalRows INT,
    @DeletedRows INT,
    @InsertedRows INT,
    @UpdatedRows INT,
    @MaxDeleteAllowed INT;

SELECT @TotalRows = COUNT(*) 
FROM Staging.[dbo].[WODS_Comp_test223];

SET @MaxDeleteAllowed = CEILING(@TotalRows * 0.15);

DECLARE @MergeOutput TABLE
(
    ActionType NVARCHAR(10),
    KeyValue NVARCHAR(4000)
);

BEGIN TRANSACTION;

MERGE Staging.[dbo].[WODS_Comp_test223] AS trgt
USING Staging.[stage].[WODS_Comp_test223] AS src
    ON trgt.[BASE_ID] = src.[BASE_ID]
    AND trgt.[LOT_ID] = src.[LOT_ID]
    AND trgt.[SPLIT_ID] = src.[SPLIT_ID]
    AND trgt.[SUB_ID] = src.[SUB_ID]

WHEN MATCHED AND
(
    ISNULL(trgt.[start_date], '19000101') <> ISNULL(src.[start_date], '19000101')
    OR ISNULL(trgt.[CLOSE_DATE], '19000101') <> ISNULL(src.[CLOSE_DATE], '19000101')
    OR ISNULL(trgt.[DESIRED_WANT_DATE], '19000101') <> ISNULL(src.[DESIRED_WANT_DATE], '19000101')
    OR ISNULL(trgt.[EXP/FLT], '') <> ISNULL(src.[EXP/FLT], '')
    OR ISNULL(trgt.[TYPE], '') <> ISNULL(src.[TYPE], '')
    OR ISNULL(trgt.[PART_ID], '') <> ISNULL(src.[PART_ID], '')
    OR ISNULL(trgt.[DESIRED_QTY], -33000) <> ISNULL(src.[DESIRED_QTY], -33000)
    OR ISNULL(trgt.[STATUS], '') <> ISNULL(src.[STATUS], '')
    OR ISNULL(trgt.[CUSTOMER_ORDER], '') <> ISNULL(src.[CUSTOMER_ORDER], '')
    OR ISNULL(trgt.[LINE_NO], -32768) <> ISNULL(src.[LINE_NO], -32768)
    OR ISNULL(trgt.[CUSTOMER_ID2], '') <> ISNULL(src.[CUSTOMER_ID2], '')
    OR ISNULL(trgt.[CUSTOMER_ID], '') <> ISNULL(src.[CUSTOMER_ID], '')
    OR ISNULL(trgt.[EndItem_Part_id], '') <> ISNULL(src.[EndItem_Part_id], '')
    OR ISNULL(trgt.[EndItem_Buyer_User_ID], '') <> ISNULL(src.[EndItem_Buyer_User_ID], '')
    OR ISNULL(trgt.[Allocation_Type], '') <> ISNULL(src.[Allocation_Type], '')
    OR ISNULL(trgt.[buyer_ptr], '') <> ISNULL(src.[buyer_ptr], '')
    OR ISNULL(trgt.[CurrentOperation], -33000) <> ISNULL(src.[CurrentOperation], -33000)
    OR ISNULL(trgt.[StatusCurrOp], -32768) <> ISNULL(src.[StatusCurrOp], -32768)
    OR ISNULL(trgt.[RESOURCE_ID], '') <> ISNULL(src.[RESOURCE_ID], '')
    OR ISNULL(trgt.[PRINTED_DATE], '19000101') <> ISNULL(src.[PRINTED_DATE], '19000101')
    OR ISNULL(trgt.[CREATE_DATE], '19000101') <> ISNULL(src.[CREATE_DATE], '19000101')
    OR ISNULL(trgt.[remaining_operations], '') <> ISNULL(src.[remaining_operations], '')
    OR ISNULL(trgt.[QTY_ON_HAND], -33000) <> ISNULL(src.[QTY_ON_HAND], -33000)
    OR ISNULL(trgt.[QTY_IN_DEMAND], -33000) <> ISNULL(src.[QTY_IN_DEMAND], -33000)
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
    OR ISNULL(trgt.[CO_AMOUNT], -33000) <> ISNULL(src.[CO_AMOUNT], -33000)
    OR ISNULL(trgt.[UNIT_PRICE], -33000) <> ISNULL(src.[UNIT_PRICE], -33000)
    OR ISNULL(trgt.[TOTAL_AMT_SHIPPED], -33000) <> ISNULL(src.[TOTAL_AMT_SHIPPED], -33000)
    OR ISNULL(trgt.[COL_AMOUNT], -33000) <> ISNULL(src.[COL_AMOUNT], -33000)
    OR ISNULL(trgt.[TimeLimit], -33000) <> ISNULL(src.[TimeLimit], -33000)
)
THEN UPDATE SET
    trgt.[start_date] = src.[start_date],
    trgt.[CLOSE_DATE] = src.[CLOSE_DATE],
    trgt.[DESIRED_WANT_DATE] = src.[DESIRED_WANT_DATE],
    trgt.[EXP/FLT] = src.[EXP/FLT],
    trgt.[TYPE] = src.[TYPE],
    trgt.[PART_ID] = src.[PART_ID],
    trgt.[DESIRED_QTY] = src.[DESIRED_QTY],
    trgt.[STATUS] = src.[STATUS],
    trgt.[CUSTOMER_ORDER] = src.[CUSTOMER_ORDER],
    trgt.[LINE_NO] = src.[LINE_NO],
    trgt.[CUSTOMER_ID2] = src.[CUSTOMER_ID2],
    trgt.[CUSTOMER_ID] = src.[CUSTOMER_ID],
    trgt.[EndItem_Part_id] = src.[EndItem_Part_id],
    trgt.[EndItem_Buyer_User_ID] = src.[EndItem_Buyer_User_ID],
    trgt.[Allocation_Type] = src.[Allocation_Type],
    trgt.[buyer_ptr] = src.[buyer_ptr],
    trgt.[CurrentOperation] = src.[CurrentOperation],
    trgt.[StatusCurrOp] = src.[StatusCurrOp],
    trgt.[RESOURCE_ID] = src.[RESOURCE_ID],
    trgt.[PRINTED_DATE] = src.[PRINTED_DATE],
    trgt.[CREATE_DATE] = src.[CREATE_DATE],
    trgt.[remaining_operations] = src.[remaining_operations],
    trgt.[QTY_ON_HAND] = src.[QTY_ON_HAND],
    trgt.[QTY_IN_DEMAND] = src.[QTY_IN_DEMAND],
    trgt.[BUYER_USER_ID] = src.[BUYER_USER_ID],
    trgt.[PLANNER_USER_ID] = src.[PLANNER_USER_ID],
    trgt.[COMMODITY_CODE] = src.[COMMODITY_CODE],
    trgt.[DESCRIPTION] = src.[DESCRIPTION],
    trgt.[USER_10] = src.[USER_10],
    trgt.[col_user_1] = src.[col_user_1],
    trgt.[RWPart] = src.[RWPart],
    trgt.[Report_Part] = src.[Report_Part],
    trgt.[CUSTOMER_PO_REF] = src.[CUSTOMER_PO_REF],
    trgt.[WORK_ORDER_NOTES] = src.[WORK_ORDER_NOTES],
    trgt.[CUST_ORD_CREATEDATE] = src.[CUST_ORD_CREATEDATE],
    trgt.[PartMaterialType] = src.[PartMaterialType],
    trgt.[Alloy] = src.[Alloy],
    trgt.[MaterialType] = src.[MaterialType],
    trgt.[CO_AMOUNT] = src.[CO_AMOUNT],
    trgt.[UNIT_PRICE] = src.[UNIT_PRICE],
    trgt.[TOTAL_AMT_SHIPPED] = src.[TOTAL_AMT_SHIPPED],
    trgt.[COL_AMOUNT] = src.[COL_AMOUNT],
    trgt.[TimeLimit] = src.[TimeLimit]

WHEN NOT MATCHED BY TARGET THEN
INSERT
(
    [start_date],
    [CLOSE_DATE],
    [DESIRED_WANT_DATE],
    [EXP/FLT],
    [BASE_ID],
    [LOT_ID],
    [SPLIT_ID],
    [SUB_ID],
    [TYPE],
    [PART_ID],
    [DESIRED_QTY],
    [STATUS],
    [CUSTOMER_ORDER],
    [LINE_NO],
    [CUSTOMER_ID2],
    [CUSTOMER_ID],
    [EndItem_Part_id],
    [EndItem_Buyer_User_ID],
    [Allocation_Type],
    [buyer_ptr],
    [CurrentOperation],
    [StatusCurrOp],
    [RESOURCE_ID],
    [PRINTED_DATE],
    [CREATE_DATE],
    [remaining_operations],
    [QTY_ON_HAND],
    [QTY_IN_DEMAND],
    [BUYER_USER_ID],
    [PLANNER_USER_ID],
    [COMMODITY_CODE],
    [DESCRIPTION],
    [USER_10],
    [col_user_1],
    [RWPart],
    [Report_Part],
    [CUSTOMER_PO_REF],
    [WORK_ORDER_NOTES],
    [CUST_ORD_CREATEDATE],
    [PartMaterialType],
    [Alloy],
    [MaterialType],
    [CO_AMOUNT],
    [UNIT_PRICE],
    [TOTAL_AMT_SHIPPED],
    [COL_AMOUNT],
    [TimeLimit]
)
VALUES
(
    src.[start_date],
    src.[CLOSE_DATE],
    src.[DESIRED_WANT_DATE],
    src.[EXP/FLT],
    src.[BASE_ID],
    src.[LOT_ID],
    src.[SPLIT_ID],
    src.[SUB_ID],
    src.[TYPE],
    src.[PART_ID],
    src.[DESIRED_QTY],
    src.[STATUS],
    src.[CUSTOMER_ORDER],
    src.[LINE_NO],
    src.[CUSTOMER_ID2],
    src.[CUSTOMER_ID],
    src.[EndItem_Part_id],
    src.[EndItem_Buyer_User_ID],
    src.[Allocation_Type],
    src.[buyer_ptr],
    src.[CurrentOperation],
    src.[StatusCurrOp],
    src.[RESOURCE_ID],
    src.[PRINTED_DATE],
    src.[CREATE_DATE],
    src.[remaining_operations],
    src.[QTY_ON_HAND],
    src.[QTY_IN_DEMAND],
    src.[BUYER_USER_ID],
    src.[PLANNER_USER_ID],
    src.[COMMODITY_CODE],
    src.[DESCRIPTION],
    src.[USER_10],
    src.[col_user_1],
    src.[RWPart],
    src.[Report_Part],
    src.[CUSTOMER_PO_REF],
    src.[WORK_ORDER_NOTES],
    src.[CUST_ORD_CREATEDATE],
    src.[PartMaterialType],
    src.[Alloy],
    src.[MaterialType],
    src.[CO_AMOUNT],
    src.[UNIT_PRICE],
    src.[TOTAL_AMT_SHIPPED],
    src.[COL_AMOUNT],
    src.[TimeLimit]
)

WHEN NOT MATCHED BY SOURCE THEN DELETE

OUTPUT $action, DELETED.[BASE_ID]
INTO @MergeOutput(ActionType, KeyValue);

-- Count all action types (after MERGE completes)
SELECT 
    @InsertedRows = ISNULL(SUM(CASE WHEN ActionType = 'INSERT' THEN 1 ELSE 0 END), 0),
    @UpdatedRows = ISNULL(SUM(CASE WHEN ActionType = 'UPDATE' THEN 1 ELSE 0 END), 0),
    @DeletedRows = ISNULL(SUM(CASE WHEN ActionType = 'DELETE' THEN 1 ELSE 0 END), 0)
FROM @MergeOutput;

-- Directional gate: only flag excessive deletes (allow growth)
DECLARE @FinalRowCount INT;
DECLARE @ErrorMsg NVARCHAR(500);
SELECT @FinalRowCount = COUNT(*) FROM Staging.[dbo].[WODS_Comp_test223];

IF @DeletedRows > @MaxDeleteAllowed
BEGIN
    ROLLBACK;
    SET @ErrorMsg = 'MERGE aborted: ' + CAST(@DeletedRows AS VARCHAR(10)) + ' deletes exceeds threshold of ' + CAST(@MaxDeleteAllowed AS VARCHAR(10));
    THROW 50001, @ErrorMsg, 1;
END
ELSE
BEGIN
    COMMIT;
    PRINT 'MERGE committed: +' + CAST(@InsertedRows AS VARCHAR(10)) + ' inserts, +' + CAST(@UpdatedRows AS VARCHAR(10)) + ' updates, -' + CAST(@DeletedRows AS VARCHAR(10)) + ' deletes';
    PRINT '  Target table now contains ' + CAST(@FinalRowCount AS VARCHAR(10)) + ' rows';
END;