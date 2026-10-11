-- b -- administration - morning report
-- check if granted one or more but no user id

WITH DAT_X AS (
	SELECT CASE
			WHEN EE.ID IS NULL THEN 'NOT IN VISUAL'
			ELSE ''
		END + '' + 
		CASE
			WHEN EE.[ACTIVE] != (CASE
				WHEN ADP.[Position Status] = 'ACTIVE' THEN 'Y'
				WHEN ADP.[Position Status] = 'LEAVE' THEN 'Y'
				ELSE 'N'
				END) THEN 'STATUS'
			ELSE ''
		END + '' +
		CASE
			WHEN ADP.[Last Name] != EE.[LAST_NAME] THEN 'LAST NAME'
			ELSE ''
		END + '' +
		CASE
			WHEN ADP.[First Name] != EE.[FIRST_NAME] THEN 
					CASE
						WHEN ADP.[Preferred Name] = 'ANN' AND ADP.[LAST NAME] = 'WENTZKE' THEN ''
						WHEN ADP.[Preferred Name] != EE.[FIRST_NAME] THEN 'FIRST NAME'
						ELSE ''
					END
			ELSE ''
		END + '' +
		CASE
			WHEN ADP.[Home Department Code] != EE.[DEPARTMENT_ID] THEN 'DEPARTMENT'
			ELSE ''
		END + '' +
		CASE
			WHEN RIGHT('0' + CONVERT(NVARCHAR(1), ADP.[Assigned Shift Code]), 2) != EE.[SHIFT_ID] THEN 'SHIFT'
			ELSE ''
		END + '' +
		CASE
			WHEN (ADP.[Reports To Name] = '' OR ADP.[Reports To Name] IS NULL) AND EE.ID != '1262' THEN 'SUPERVISOR'
			ELSE ''
		END + '' +
		CASE
			WHEN ADP.[File Number] = '004139' AND ADP.[Work Contact: Work Email] != EE.[EMAIL_ADDR] THEN ''
			WHEN ADP.[Work Contact: Work Email] != EE.[EMAIL_ADDR] AND EE.[EMAIL_ADDR] IS NOT NULL THEN 'EMAIL'
			ELSE ''
		END AS [ERROR]
		, CASE WHEN ADP.[File Number]  < 4
	         THEN RIGHT('000' + CAST(ADP.[File Number]  AS VARCHAR(10)), 6)  
      	     ELSE RIGHT('000' + CAST(ADP.[File Number]  AS VARCHAR(10)), 6) 
	    END  AS ADP_ID
		, EE.ID AS VISUAL_ID
		, ADP.[Last Name] AS ADP_LNAME
		, EE.[LAST_NAME] AS VISUAL_LNAME
		, ADP.[First Name] AS ADP_FNAME
		, ADP.[Preferred Name] AS ADP_PREFERRED
		, EE.[FIRST_NAME] AS VISUAL_FNAME
		, ADP.[Position Status] AS ADP_STATUS
		, EE.[ACTIVE] AS VISUAL_STATUS
		, ADP.[Location Code]
		, ADP.[Home Department Code] AS ADP_DEPT
		, EE.DEPARTMENT_ID AS VISUAL_DEPT
		, ADP.[Reports To Name]
		, ADP.[Assigned Shift Code] AS ADP_SHIFT
		, EE.SHIFT_ID AS VISUAL_SHIFT
		, ADP.[Work Contact: Work Email]
		, EE.EMAIL_ADDR
	FROM [LIVESupplemental].[dbo].[ADP_EMP] ADP
	LEFT OUTER JOIN LIVE.[dbo].[EMPLOYEE] EE
		ON RIGHT('000000' + EE.ID, 6) = ADP.[File Number]
	WHERE (EE.[ACTIVE] = 'Y'
		OR (CASE
			WHEN LEFT(ADP.[Home Department Code], 3) = '800' THEN 'N'
--> INTERNS NOT IN VISUAL
			WHEN ADP.[File Number] IN ('004177', '004178', '004179', '004180', '004181', '004182', '004183', '004184') THEN 'N'  
			WHEN ADP.[Position Status] = 'ACTIVE' THEN 'Y'
			--WHEN ADP.[Position Status] = 'LEAVE' THEN 'Y'
			ELSE 'N'
		END = 'Y'))
		AND (EE.ID NOT IN ('0104', '0148', '2458') OR EE.ID IS NULL)
	--> 0104 AND 0148 WERE DUPLICATE EE RECORDS
	--> 2458 IS FOR KARALEE LOVELAND WHO IS CURRENTLY CONTRACTING
		AND ([Hire Date] < GETDATE() AND [Rehire Date] <= GETDATE())

)
,DAT_Y AS (
	SELECT CASE
			WHEN ADP.[File Number] IS NULL THEN 'NOT IN ADP'
			ELSE ''
		END AS [ERROR]
		, ADP.[File Number] AS ADP_ID
		, EE.ID AS VISUAL_ID
		, ADP.[Last Name] AS ADP_LNAME
		, EE.[LAST_NAME] AS VISUAL_LNAME
		, ADP.[First Name] AS ADP_FNAME
		, ADP.[Preferred Name] AS ADP_PREFERRED
		, EE.[FIRST_NAME] AS VISUAL_FNAME
		, ADP.[Position Status] AS ADP_STATUS
		, EE.[ACTIVE] AS VISUAL_STATUS
		, ADP.[Location Code]
		, ADP.[Home Department Code] AS ADP_DEPT
		, EE.DEPARTMENT_ID AS VISUAL_DEPT
		, ADP.[Reports To Name]
		, ADP.[Assigned Shift Code] AS ADP_SHIFT
		, EE.SHIFT_ID AS VISUAL_SHIFT
		, ADP.[Work Contact: Work Email]
		, EE.EMAIL_ADDR
	FROM LIVE.[dbo].[EMPLOYEE] EE
	LEFT OUTER JOIN [LIVESupplemental].[dbo].[ADP_EMP] ADP
		ON RIGHT('000000' + EE.ID, 6) = ADP.[File Number]
	WHERE EE.[ACTIVE] = 'Y'
	--> REMOVE INTERNS FROM CONSIDERATION
		AND LEFT(EE.ID, 3) NOT IN ('INT', 'AIP')
		AND ([Hire Date] < GETDATE() AND [Rehire Date] <= GETDATE())
		AND ADP.[File Number] IS NULL
)

, CTE_SLCT AS
( SELECT 
   Distinct 
   -- 1 --------------------- has permissions but the user record not bound to ee
        'NOUSERRECORD' AS [ERROR]
		, CASE WHEN ADP.[File Number]  < 4
	         THEN RIGHT('000' + CAST(ADP.[File Number]  AS VARCHAR(10)), 6)  
      	     ELSE RIGHT('000' + CAST(ADP.[File Number]  AS VARCHAR(10)), 6) 
	    END  AS ADP_ID
		, EE.ID AS VISUAL_ID
		, ADP.[Last Name] AS ADP_LNAME
		, EE.[LAST_NAME] AS VISUAL_LNAME
		, ADP.[First Name] AS ADP_FNAME
		, ADP.[Preferred Name] AS ADP_PREFERRED
		, EE.[FIRST_NAME] AS VISUAL_FNAME
		, ADP.[Position Status] AS ADP_STATUS
		, EE.[ACTIVE] AS VISUAL_STATUS
		, ADP.[Location Code]
		, ADP.[Home Department Code] AS ADP_DEPT
		, EE.DEPARTMENT_ID AS VISUAL_DEPT
		, ADP.[Reports To Name]
		, ADP.[Assigned Shift Code] AS ADP_SHIFT
		, EE.SHIFT_ID AS VISUAL_SHIFT
		, ADP.[Work Contact: Work Email]
		, EE.EMAIL_ADDR
   -- -----------------------
	, A.PROGRAM_ID
	, CASE
		WHEN U.PERMISSION IN ('N', 'R', 'Y') THEN ISNULL(PROFILE_STRING, PERMISSION)
		ELSE ''
	END AS [PERMISSION]
	--, EE.*
from EMPLOYEE EE

LEFT OUTER JOIN [USER_PGM_AUTHORITY] U
	ON U.[USER_ID] = EE.[USER_ID]

LEFT OUTER JOIN APPLICATION A
	ON A.PROGRAM_ID = U.PROGRAM_ID

LEFT JOIN LIVESupplemental.dbo.ADP_EMP ADP
	ON CONVERT(NVARCHAR(15), RIGHT('0000' + EE.ID, 6)) = ADP.[File Number]

-- check if U.[USER_ID] is null which mens the user record was not bound to the employee record
-- and if to be granted

where U.[USER_ID] is null 
-- --- can use in test
-- Where U.[USER_ID] = 'cameronF'
), DAT_A AS (
SELECT 1 COL
)
, DAT_B AS (
SELECT * FROM CTE_SLCT
PIVOT(MAX(PERMISSION)
	FOR PROGRAM_ID IN (LMC_VEXP, VFAPCENT, VFAPIENT, VFAPSCHD, VFAPVINQ, VFARCENT, VFARCINQ, VFARCLCT, VFARIENT, VFBNKMNT
	, VFCASHBK, VFCONSOL, VFCSHWIN, VFGLAWIN, VFGLBMNT, VFGLTENT, VFMFGJRN, VFREVALU, VMALCUTL, VMBOMRPT, VMCBKRPT, VMCBORPT
	, VMCSJRPT, VMCSTBOM, VMCUSINQ, VMCUSMNT, VMDOCMNT, VMECNENT, VMECNHST, VMEMPMNT, VMENGRPT, VMIBTENT, VMIBTRCV, VMIBTSHP
	, VMINVENT, VMINVGEN, VMLABENT, VMMFGWIN, VMORDENT, VMORDWIN, VMPBCENT, VMPFTRPT, VMPHYINV, VMPIVRPT, VMPLNWIN, VMPRTMNT
	, VMPURENT, VMPURWIN, VMRCVENT, VMRCVINS, VMRCVRPT, VMREQENT, VMRESMNT, VMREVRPT, VMRFQENT, VMSCHRPT, VMSCHWIN, VMSDSRPT
	, VMSHPENT, VMSRVDIS, VMSRVENT, VMSRVMNT, VMSRVPLN, VMSUPPFM, VMTHRWIN, VMUMTMNT, VMVNDINQ, VMVNDMNT, VMWHSMNT, VMWIPRPT
	, VMWRKCST, VMWRQRPT, VTMATTRC, VTTRCMNT, VTTRPMNT)
) AS [PIVOTTABLE]

WHERE EXISTS
(
    SELECT 1
    FROM (VALUES
     -- if one or more null
	 
		(VFAPCENT),
		(VFAPIENT),
		(VFAPSCHD),
		(VFAPVINQ),
		(VFARCENT),
		(VFARCINQ),
		(VFARCLCT),
		(VFARIENT),
		(VFBNKMNT),
		(VFCASHBK),
		(VFCONSOL),
		(VFCSHWIN),
		(VFGLAWIN),
		(VFGLBMNT),
		(VFGLTENT),
		(VFMFGJRN),
		(VFREVALU),
		(VMALCUTL),
		(VMBOMRPT),
		(VMCBKRPT),
		(VMCBORPT),
		(VMCSJRPT),
		(VMCSTBOM),
		(VMCUSINQ),
		(VMCUSMNT),
		(VMDOCMNT),
		(VMECNENT),
		(VMECNHST),
		(VMEMPMNT),
		(VMENGRPT),
		(VMIBTENT),
		(VMIBTRCV),
		(VMIBTSHP),
		(VMINVENT),
		(VMINVGEN),
		(VMLABENT),
		(VMMFGWIN),
		(VMORDENT),
		(VMORDWIN),
		(VMPBCENT),
		(VMPFTRPT),
		(VMPHYINV),
		(VMPIVRPT),
		(VMPLNWIN),
		(VMPRTMNT),
		(VMPURENT),
		(VMPURWIN),
		(VMRCVENT),
		(VMRCVINS),
		(VMRCVRPT),
		(VMREQENT),
		(VMRESMNT),
		(VMREVRPT),
		(VMRFQENT),
		(VMSCHRPT),
		(VMSCHWIN),
		(VMSDSRPT),
		(VMSHPENT),
		(VMSRVDIS),
		(VMSRVENT),
		(VMSRVMNT),
		(VMSRVPLN),
		(VMSUPPFM),
		(VMTHRWIN),
		(VMUMTMNT),
		(VMVNDINQ),
		(VMVNDMNT),
		(VMWHSMNT),
		(VMWIPRPT),
		(VMWRKCST),
		(VMWRQRPT),
		(VTMATTRC),
		(VTTRCMNT),
		(VTTRPMNT)
    ) v(col)
    WHERE v.col IS NOT NULL
)
), DAT_C AS (
SELECT 
	ERROR
,	ADP_ID
,	VISUAL_ID
,	ADP_LNAME
,	VISUAL_LNAME
,	ADP_FNAME
,	ADP_PREFERRED
,	VISUAL_FNAME
,	ADP_STATUS
,	VISUAL_STATUS
,	[Location Code]
,	ADP_DEPT
,	VISUAL_DEPT
,	[Reports To Name]
,	ADP_SHIFT
,	VISUAL_SHIFT
,	[Work Contact: Work Email]
,	EMAIL_ADDR

	
FROM DAT_B
)
SELECT * FROM(
select * from DAT_X
UNION ALL
select * from DAT_Y
UNION ALL
SELECT * FROM DAT_C
) AS [FINAL]
WHERE REPLACE([ERROR], '; ', '') != ''