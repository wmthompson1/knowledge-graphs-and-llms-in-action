USE [LIVE]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
Review Notes (Markuo)
1. The original function repeats key lookups (status, last operation, next eligible operation).
2. This refactor computes shared values once to simplify maintenance.
3. Behavior is preserved, including NULL returns when status branches do not match C/R.
4. Base table references are schema-qualified.
*/

---CREATE OR ALTER FUNCTION [dbo].[sfn_current_operation]
(
    @workorder_type      NVARCHAR(1),
    @workorder_base_id   NVARCHAR(30),
    @workorder_lot_id    NVARCHAR(3),
    @workorder_split_id  NVARCHAR(3),
    @workorder_sub_id    NVARCHAR(3)
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
    DECLARE @LastOpStatus INT;
    DECLARE @LastOpLabor INT;
    DECLARE @LastOperation INT;
    DECLARE @WorkOrderStatus NCHAR(1);
    DECLARE @NextEligibleOperation INT;

    SET @LastOpStatus = ISNULL(
        dbo.sfn_getlastopcompleted(
            @workorder_type,
            @workorder_base_id,
            @workorder_lot_id,
            @workorder_split_id,
            @workorder_sub_id
        ),
        0
    );

    SET @LastOpLabor = ISNULL(
        dbo.ufn_getlastoplaborticketfromwo(
            @workorder_type,
            @workorder_base_id,
            @workorder_lot_id,
            @workorder_split_id,
            @workorder_sub_id
        ),
        0
    );

    SET @LastOperation = dbo.ufn_GetLastOperation(
        @workorder_base_id,
        @workorder_lot_id,
        @workorder_sub_id,
        @workorder_split_id,
        @workorder_type
    );

    SELECT TOP (1)
        @WorkOrderStatus = wo.[STATUS]
    FROM [dbo].[WORK_ORDER] wo
    WHERE wo.BASE_ID = @workorder_base_id
      AND wo.LOT_ID = @workorder_lot_id
      AND wo.SPLIT_ID = @workorder_split_id
      AND wo.SUB_ID = @workorder_sub_id
      AND wo.[TYPE] = @workorder_type;

    SELECT TOP (1)
        @NextEligibleOperation = o.SEQUENCE_NO
    FROM [dbo].[OPERATION] o
    WHERE o.WORKORDER_BASE_ID = @workorder_base_id
      AND o.WORKORDER_LOT_ID = @workorder_lot_id
      AND o.WORKORDER_SPLIT_ID = @workorder_split_id
      AND o.WORKORDER_SUB_ID = @workorder_sub_id
      AND o.WORKORDER_TYPE = @workorder_type
      AND o.SEQUENCE_NO > @LastOpStatus
      AND o.[STATUS] IN ('F', 'R', 'U')
    ORDER BY o.SEQUENCE_NO;

    IF @LastOpStatus > @LastOpLabor
    BEGIN
        IF @LastOpStatus = @LastOperation
        BEGIN
            IF @WorkOrderStatus = 'C'
                SET @Result = NULL;
            ELSE IF @WorkOrderStatus = 'R'
                SET @Result = @LastOpStatus;
            ELSE
                SET @Result = NULL;
        END
        ELSE IF (@LastOpStatus + @LastOpLabor) = 0
        BEGIN
            SET @Result = dbo.ufn_GetFirstOperation(
                @workorder_base_id,
                @workorder_lot_id,
                @workorder_sub_id,
                @workorder_split_id,
                @workorder_type
            );
        END
        ELSE
        BEGIN
            SET @Result = @NextEligibleOperation;
        END
    END
    ELSE IF @LastOpStatus < @LastOpLabor
    BEGIN
        SET @Result = @LastOpLabor;
    END
    ELSE
    BEGIN
        IF @LastOpStatus = @LastOperation
        BEGIN
            IF @WorkOrderStatus = 'C'
                SET @Result = NULL;
            ELSE IF @WorkOrderStatus = 'R'
                SET @Result = @LastOpStatus;
            ELSE
                SET @Result = NULL;
        END
        ELSE
        BEGIN
            SET @Result = @NextEligibleOperation;
        END
    END

    RETURN @Result;
END
GO
