USE [LIVE]
GO

/****** Object:  UserDefinedFunction [dbo].[sfn_current_operation]    Script Date: 6/10/2026 12:36:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






/***************************************************
-- =============================================
-- Author:		Vivian Elia
-- Create date: 6/9/2017
-- Description:	Retrieves the current operation by checking last completed operation with last worked operation and obtaining the greatest one.
-- This uses both operation status and labor tickets
-- modified 8/17/2017 
-- removed operation table and left results of case statement as the result
-- PRE 8/17/2017 Query below was determined to be incorrect.  Instead of the next operation, should be returning the current operation:
--	SELECT TOP 1
--FROM OPERATION O
--WHERE O.WORKORDER_BASE_ID = @workorder_base_id
--	AND O.WORKORDER_LOT_ID = @workorder_lot_id
--	AND O.WORKORDER_SPLIT_ID = @workorder_split_id
--	AND O.WORKORDER_SUB_ID = @workorder_sub_id
--	AND O.WORKORDER_TYPE = @workorder_type
--	AND O.SEQUENCE_NO = 
--		CASE WHEN isnull(dbo.sfn_getlastopcompleted(@workorder_type, @workorder_base_id, @workorder_lot_id, @workorder_split_id, @workorder_sub_id),0) 
--		     >=	isnull(dbo.ufn_getlastoplaborticketfromwo(@workorder_type, @workorder_base_id, @workorder_lot_id, @workorder_split_id, @workorder_sub_id),0)
--		THEN isnull(dbo.sfn_getlastopcompleted(@workorder_type, @workorder_base_id, @workorder_lot_id, @workorder_split_id, @workorder_sub_id),0)
--		ELSE isnull(dbo.ufn_getlastoplaborticketfromwo(@workorder_type, @workorder_base_id, @workorder_lot_id, @workorder_split_id, @workorder_sub_id),0)
--	END
	-- Return the result of the function
-- =============================================
-- 1/5/2021 - MP; Updated to only reflect firmed and released Operations per Anne W via Spiceworks ticket 114

TESTER:

  
--,'1627370'  -- zero complete Firmed wo
--,'1523446'    -- partial complete
--, '1627370'    -- zero complete firmed wo
--, '1627371'		-- partial complete R
--, '1627372'		-- partial complete R

--, '1627474'			-- Firmed Top of Wods - 1627474/1
--, '1623409'		-- Firmed 2 top of wods - 1623409/1
--, '1623437'		-- Firmed 3 top of wods  - 1623437/1

--, '1617025'			-- Firmed Top of Wods - 1617025/1
--, '1607510'		-- Firmed 2 top of wods - 1607510/1
,( '1626866')		-- Firmed 3 top of wods  - 1626866/1

-- ~
declare
 @_workorder_type		NVARCHAR(1) 	= 'W' -- ty,
,@_workorder_base_id	NVARCHAR(30) 	= '1626866' -- ba,
,@_workorder_lot_id		NVARCHAR(3) 	=  '1'  --lo,
,@_workorder_split_id	NVARCHAR(3) 	=  '0'  --sp,
,@_workorder_sub_id		NVARCHAR(3) 	=  '0'  --su

select isnull(dbo.sfn_current_operation(@_workorder_type, @_workorder_base_id
, @_workorder_lot_id, @_workorder_split_id, @_workorder_sub_id),0) as sfn_current_operation

select isnull(dbo.sfn_getlastopcompleted(@_workorder_type, @_workorder_base_id, @_workorder_lot_id
, @_workorder_split_id, @_workorder_sub_id),0) sfn_getlastopcompleted



**************************************************/



CREATE FUNCTION [dbo].[sfn_current_operation] 
(
	-- Add the parameters for the function here
	
	-- Add the parameters for the function here
	   @workorder_type         AS Nvarchar(1), 
	   @workorder_base_id      AS Nvarchar(30), 
	   @workorder_lot_id	  AS Nvarchar(3),
	   @workorder_split_id	  AS Nvarchar(3),
	   @workorder_sub_id	  as Nvarchar(3)

)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int
		, @LastOpStatus int
		, @LastOpLabor int
	-- Add the T-SQL statements to compute the return value here
	--max operation w/ closed status
	SET @LastOpStatus = isnull(dbo.sfn_getlastopcompleted(@workorder_type, @workorder_base_id, @workorder_lot_id, @workorder_split_id, @workorder_sub_id),0) 
	--max operation with a labor ticket (looking at labor ticket table)
	SET @LastOpLabor = isnull(dbo.ufn_getlastoplaborticketfromwo(@workorder_type, @workorder_base_id, @workorder_lot_id, @workorder_split_id, @workorder_sub_id),0)

	SELECT  @Result = 
	CASE
		
		WHEN @LastOpStatus --max closed operation
			 > @LastOpLabor -- max operation w/ Labor
			--OR isnull(dbo.sfn_getlastopcompleted(@workorder_type, @workorder_base_id, @workorder_lot_id, @workorder_split_id, @workorder_sub_id),0) 
			--	= isnull(dbo.ufn_getlastoplaborticketfromwo(@workorder_type, @workorder_base_id, @workorder_lot_id, @workorder_split_id, @workorder_sub_id),0)
		
		THEN 
			CASE WHEN @LastOpStatus --max closed operation
				= [dbo].[ufn_GetLastOperation](@workorder_base_id,@workorder_lot_id,@workorder_sub_id,@workorder_split_id,@workorder_type) --last operation
				THEN 
								CASE WHEN (
									SELECT TOP 1 STATUS FROM WORK_ORDER 
									WHERE BASE_ID = @workorder_base_id 
										AND LOT_ID = @workorder_lot_id
										AND SPLIT_ID = @workorder_split_id
										AND SUB_ID = @workorder_sub_id
										AND TYPE = @workorder_type
										) = 'C' --work order level status is closed
									THEN NULL
									WHEN (SELECT STATUS FROM WORK_ORDER 
										WHERE BASE_ID = @workorder_base_id 
											AND LOT_ID = @workorder_lot_id
											AND SPLIT_ID = @workorder_split_id
											AND SUB_ID = @workorder_sub_id
											AND TYPE = @workorder_type
										) = 'R' --work ordder level status is released.
									THEN @LastOpStatus
						
								END
				
				WHEN @LastOpStatus
					 + @LastOpLabor = 0
				--ufn_GetFirstOperation was modified to only get 1st firmed or released operation (vs just the first).  1/5/2021; MP; Per Spiceworks Ticket 114 from Anne W.
				THEN [dbo].[ufn_GetFirstOperation](@workorder_base_id, @workorder_lot_id, @workorder_sub_id,@workorder_split_id, @workorder_type)
				
				--(SELECT MIN(SEQUENCE_NO) FROM OPERATION O 
				--		WHERE O.WORKORDER_BASE_ID  = @workorder_base_id
				--			AND O.WORKORDER_LOT_ID   = @workorder_lot_id
				--			AND O.WORKORDER_SPLIT_ID = @workorder_split_id
				--			AND O.WORKORDER_SUB_ID   = @workorder_sub_id
				--			AND O.WORKORDER_TYPE     = @workorder_type
				--	)	
				ELSE 
					(SELECT TOP 1 SEQUENCE_NO 
						FROM OPERATION O
						WHERE O.WORKORDER_BASE_ID  = @workorder_base_id
							AND O.WORKORDER_LOT_ID   = @workorder_lot_id
							AND O.WORKORDER_SPLIT_ID = @workorder_split_id
							AND O.WORKORDER_SUB_ID   = @workorder_sub_id
							AND O.WORKORDER_TYPE     = @workorder_type
							AND O.SEQUENCE_NO > @LastOpStatus
							--get 1st firmed, un-released or released operation (vs just the first).  1/5/2021; MP; Per Spiceworks Ticket 114 from Anne W.
							and o.status in ('F','R','U')
							--1/5/2021 - in the even operations inserted (out of order), below will ensure it gets the first sequenial operation
							order by o.sequence_no
					)
			END 
		WHEN @LastOpStatus
					< @LastOpLabor
		THEN @LastOpLabor
			
		WHEN @LastOpStatus
			 = @LastOpLabor
		THEN 
			CASE 
				WHEN @LastOpStatus
					= [dbo].[ufn_GetLastOperation](@workorder_base_id,@workorder_lot_id,@workorder_sub_id,@workorder_split_id,@workorder_type)
				THEN 
					CASE 
						WHEN (
							SELECT TOP 1 STATUS FROM WORK_ORDER 
							WHERE BASE_ID = @workorder_base_id 
								AND LOT_ID = @workorder_lot_id
								AND SPLIT_ID = @workorder_split_id
								AND SUB_ID = @workorder_sub_id
								AND TYPE = @workorder_type
								) = 'C' --work order level status is closed
						THEN NULL
						WHEN (SELECT STATUS FROM WORK_ORDER 
								WHERE BASE_ID = @workorder_base_id 
									AND LOT_ID = @workorder_lot_id
									AND SPLIT_ID = @workorder_split_id
									AND SUB_ID = @workorder_sub_id
									AND TYPE = @workorder_type
								) = 'R' --work ordder level status is released.
						THEN @LastOpStatus
					END

				
			ELSE
			
				(
					SELECT TOP 1 SEQUENCE_NO 
					FROM OPERATION O
					WHERE O.WORKORDER_BASE_ID  = @workorder_base_id
						AND O.WORKORDER_LOT_ID   = @workorder_lot_id
						AND O.WORKORDER_SPLIT_ID = @workorder_split_id
						AND O.WORKORDER_SUB_ID   = @workorder_sub_id
						AND O.WORKORDER_TYPE     = @workorder_type
						AND O.SEQUENCE_NO > @LastOpStatus
						--get 1st firmed, un-released or released operation (vs just the first).  1/5/2021; MP; Per Spiceworks Ticket 114 from Anne W.
						and o.status in ('F','R','U')
						--1/5/2021 - in the even operations inserted (out of order), below will ensure it gets the first sequenial operation
						order by o.sequence_no
				)
			END
		END
	
	RETURN @Result

END

GO


