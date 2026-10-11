USE [LIVE]
GO

/****** Object:  UserDefinedFunction [dbo].[sfn_getlastopcompleted]    Script Date: 6/10/2026 12:40:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Vivian Elia
-- Create date: 05/19/2017
-- Description:	looks for last operation completed based on status not on labor tickets and using a workorder primary key
--UPDATE: RETURNS NULL IF NO OPERATIONS COMPLETE. 
-- =============================================

CREATE FUNCTION [dbo].sfn_getlastopcompleted
(@workorder_type AS NVARCHAR(1)
	, @workorder_base_id AS  NVARCHAR(30)
	, @workorder_lot_id AS   NVARCHAR(3)
	, @workorder_split_id AS NVARCHAR(3)
	, @workorder_sub_id AS   NVARCHAR(3)
)
RETURNS SMALLINT
AS
	BEGIN
	DECLARE @result SMALLINT;
	SELECT @result = MAX(o.sequence_no)
	FROM operation o
	WHERE o.workorder_type = @workorder_type
		AND o.workorder_base_id = @workorder_base_id
		AND o.workorder_lot_id = @workorder_lot_id
		AND o.workorder_split_id = @workorder_split_id
		AND o.workorder_sub_id = @workorder_sub_id
		AND o.status = 'C';
	RETURN @result;
	END;
GO


