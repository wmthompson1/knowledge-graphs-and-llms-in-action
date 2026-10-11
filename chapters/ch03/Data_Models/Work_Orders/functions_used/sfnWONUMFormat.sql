USE [LIVE]
GO

/****** Object:  UserDefinedFunction [dbo].[sfnWONUMFormat]    Script Date: 6/9/2026 8:25:23 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Eric Shafer
-- Create date: 5/26/2017
-- Description:	Scalar funtion to return a WO_NUM identifier.  Uses logic the business decided on BASE-SUB/LOT.SPLIT.  WHEN SUB or SPLIT is 0 supress
-- =============================================
CREATE FUNCTION [dbo].sfnWONUMFormat
(
	-- Add the parameters for the function here
	@BASE_ID NVARCHAR(30)
		, @LOT_ID NVARCHAR(3) 
		, @SPLIT_ID NVARCHAR(3)
		, @SUB_ID NVARCHAR(3) 
)
RETURNS Nvarchar(42)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result varchar(42)

	-- Add the T-SQL statements to compute the return value here
	SELECT @Result = @BASE_ID + 
		CASE WHEN ISNULL(@SUB_ID,'0') = '0' 
			THEN '' 
			ELSE '-' + @SUB_ID 
		END	+ 
		'/' + @LOT_ID + 
		CASE WHEN ISNULL(@SPLIT_ID,'0') = '0' 
			THEN '' 
			ELSE '.' + @SPLIT_ID 
		END 

	-- Return the result of the function
	RETURN @Result

END
GO

-- please convert this function to inline sql using a select from the work_order table. For schema trversl, use existing coe base and only use fields that exist

SELECT 
	BASE_ID + 
	CASE WHEN ISNULL(SUB_ID,'0') = '0' 
		THEN '' 
		ELSE '-' + SUB_ID 
	END	+ 
	'/' + LOT_ID + 
	CASE WHEN ISNULL(SPLIT_ID,'0') = '0' 
		THEN '' 
		ELSE '.' + SPLIT_ID 
	END AS WO_NUM
FROM work_order
