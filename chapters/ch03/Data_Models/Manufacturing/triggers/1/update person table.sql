---USE [CRUNCH0126]
-- use live
GO

-- -- C:\Users\williamt\OneDrive - Skills Inc GCC High\Documents\sql\20260807 Luke - Expedite Lockdown\update person table.sql

-- /**
-- MonicaD
-- Shannen
-- Bob
-- EllenM
-- **/

-- SELECT *
-- FROM [dbo].[PERSON] p

-- begin transaction
-- update p
--   set is_approver = 'N'
-- from [dbo].[PERSON] p
-- where id = 'EllenM'
-- commit tran

-- begin transaction
-- update p
--   set is_approver = 'Y'
-- from [dbo].[PERSON] p
-- where id = 'MonicaD'
-- commit tran

-- INSERT INTO [dbo].[PERSON]
--            ([ID]
--            ,[NAME]
--            ,[IS_APPROVER]
--            ,[IS_BUYER]
--            ,[IS_PLANNER]
--            ,[IS_REQUESTER])
--      VALUES
--            ('Shannen'
--            ,NULL
--            ,N'Y'
--            ,N'N'
--            ,N'N'
--            ,N'N'
-- 		   )
-- GO


-- INSERT INTO [dbo].[PERSON]
--            ([ID]
--            ,[NAME]
--            ,[IS_APPROVER]
--            ,[IS_BUYER]
--            ,[IS_PLANNER]
--            ,[IS_REQUESTER])
--      VALUES
--            ('Bob'
--            ,NULL
--            ,N'Y'
--            ,N'N'
--            ,N'N'
--            ,N'N'
-- 		   )
-- GO

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


-- note - visual adds '#' to the end of the user name e.g. CATHIE#
SELECT [ROWID]
      ,[ID]
      ,[NAME]
      ,[IS_APPROVER]
 
  FROM [dbo].[PERSON]
  where 1=1
  and id in ('monicad','Shannen','bob','ellenM','Cathie')
GO

-- Cathie@skillsinc.com

-- INSERT INTO [dbo].[PERSON]
--            ([ID]
--            ,[NAME]
--            ,[IS_APPROVER]
--            ,[IS_BUYER]
--            ,[IS_PLANNER]
--            ,[IS_REQUESTER])
--      VALUES
--            ('Cathie'
--            ,NULL
--            ,N'Y'
--            ,N'N'
--            ,N'N'
--            ,N'N'
-- 		   )
-- GO