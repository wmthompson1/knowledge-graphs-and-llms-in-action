USE [CRUNCH0126]
GO

-- C:\Users\williamt\OneDrive - Skills Inc GCC High\Documents\sql\20260807 Luke - Expedite Lockdown\update person table.sql

/**
MonicaD
Shannen
Bob
EllenM
**/

--begin transaction
--update p
--  set is_approver = 'Y'
--from [dbo].[PERSON] p
--where id = 'MonicaD'
--commit tran

--INSERT INTO [dbo].[PERSON]
--           ([ID]
--           ,[NAME]
--           ,[IS_APPROVER]
--           ,[IS_BUYER]
--           ,[IS_PLANNER]
--           ,[IS_REQUESTER])
--     VALUES
--           ('Shannen'
--           ,NULL
--           ,N'Y'
--           ,N'N'
--           ,N'N'
--           ,N'N'
--		   )
--GO


--INSERT INTO [dbo].[PERSON]
--           ([ID]
--           ,[NAME]
--           ,[IS_APPROVER]
--           ,[IS_BUYER]
--           ,[IS_PLANNER]
--           ,[IS_REQUESTER])
--     VALUES
--           ('Bob'
--           ,NULL
--           ,N'Y'
--           ,N'N'
--           ,N'N'
--           ,N'N'
--		   )
--GO

--INSERT INTO [dbo].[PERSON]
--           ([ID]
--           ,[NAME]
--           ,[IS_APPROVER]
--           ,[IS_BUYER]
--           ,[IS_PLANNER]
--           ,[IS_REQUESTER])
--     VALUES
--           ('EllenM'
--           ,NULL
--           ,N'Y'
--           ,N'N'
--           ,N'N'
--           ,N'N'
--		   )
--GO



--SELECT [ROWID]
--      ,[ID]
--      ,[NAME]
--      ,[IS_APPROVER]
--      ,[IS_BUYER]
--      ,[IS_PLANNER]
--      ,[IS_REQUESTER]
--  FROM [dbo].[PERSON]
--  where 1=1
--  and id in ('monicad','Shannen','bob','ellenM')
--GO
