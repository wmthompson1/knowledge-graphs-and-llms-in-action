-- BUR_PERCENT_RUN

  SELECT [ROWID]
      ,[RESOURCE_ID]
      ,BUR_PERCENT_SETUP  -- 122
      ,BUR_PERCENT_RUN    -- 122
  FROM [dbo].[SHOP_RESOURCE_SITE] sr
  where sr.[BUR_PERCENT_RUN] =  122

    SELECT [ROWID]
      ,[RESOURCE_ID]
      ,BUR_PERCENT_SETUP  -- 72
      ,BUR_PERCENT_RUN    -- 72
  FROM [dbo].[SHOP_RESOURCE_SITE] sr
  where sr.[BUR_PERCENT_RUN] =  72