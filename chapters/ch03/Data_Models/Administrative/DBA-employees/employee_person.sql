/****** williamt 9/30 employee_person

please create a temp table that I can use to update the person 
table (zero trust model)
do not connect or alter or modify any objects in the database directly
utilize the existing code base and lineage tools correctly.
you may refer to /@Documentation\Schema\Data_Models\Administrative\DBA-employees\README.md
and the select statement
management requests that the is_approver field of person be set to 'Y'

for the following persons
Charles Tiffany
Keryn Knight
Randall Troutman
Abdul Fountain
Christopher Maynard
Austin Shaner
Ricky Marquez
Brian Swartley
Elizabeth Goshorn
Makenzie Blakeley
Alexis Pelton
Randie Hoskins
Amanda Heath
Ron Anderson
Ronald Trotter
Ronald Whittle
Jonathon Hill Jr
Ryan Robinson
Loeuth Kloth
Charleen Oetliker
Diane Tremain
***/

/*
Zero-trust staging payload.

This script only creates and populates a session-scoped temporary table. It does
not update LIVE.dbo.PERSON or any other persistent database object.
*/

DROP TABLE IF EXISTS #person_approver_updates;

CREATE TABLE #person_approver_updates
(
    employee_id   NVARCHAR(15)  NULL,
    user_id       NVARCHAR(20)  NULL,
    person_id     NVARCHAR(20)  NULL,
    first_name    NVARCHAR(100) NOT NULL,
    last_name     NVARCHAR(100) NOT NULL,
    is_approver   CHAR(1)       NOT NULL,
    match_status  VARCHAR(20)   NOT NULL
);

DECLARE @requested_people TABLE
(
    first_name  NVARCHAR(100) NOT NULL,
    last_name   NVARCHAR(100) NOT NULL,
    is_approver CHAR(1)       NOT NULL
);

INSERT INTO @requested_people (first_name, last_name, is_approver)
VALUES
    (N'Charles', N'Tiffany', 'Y'),
    (N'Keryn', N'Knight', 'Y'),
    (N'Randall', N'Troutman', 'Y'),  -- spelling first name Randall
    (N'Abdul', N'Fountain', 'Y'),
    (N'Christopher', N'Maynard', 'Y'),    -- spelling Christopher Maynard
    (N'Austin', N'Shaner', 'Y'),
    (N'Ricky', N'Marquez', 'Y'),
    (N'Brian', N'Swartley', 'Y'),
    (N'Elizabeth', N'Goshorn', 'Y'), 
    (N'Makenzie', N'Blakeley', 'Y'),
    (N'Alexis', N'Pelton', 'Y'),
    (N'Randie', N'Hoskins', 'Y'),
    (N'Amanda', N'Heath', 'Y'),
    (N'Ron', N'Anderson', 'Y'),
    (N'Ronald', N'Trotter', 'Y'),
    (N'Ronald', N'Whittle', 'Y'),
    (N'Jonathan', N'Hill Jr', 'Y'), -- spelling Jonathan Hill Jr without the '.'
    (N'Ryan', N'Robinson', 'Y'),
    (N'Loeuth', N'Kloth', 'Y'),
    (N'Charleen', N'Oetliker', 'Y'),
    (N'Diane', N'Tremain', 'Y');

;WITH employee_matches AS
(
    SELECT
        r.first_name,
        r.last_name,
        r.is_approver,
        e.id AS employee_id,
        e.user_id,
        p.id AS person_id,
        COUNT(*) OVER
        (
            PARTITION BY r.first_name, r.last_name
        ) AS match_count
    FROM @requested_people AS r
    LEFT JOIN LIVE.dbo.EMPLOYEE AS e
        ON e.FIRST_NAME = r.first_name
       AND e.LAST_NAME = r.last_name
    LEFT JOIN LIVE.dbo.PERSON AS p
        ON p.ID = e.USER_ID
)

INSERT INTO #person_approver_updates
(
    employee_id,
    user_id,
    person_id,
    first_name,
    last_name,
    is_approver,
    match_status
)
SELECT
    employee_id,
    user_id,
    person_id,
    first_name,
    last_name,
    is_approver,
    CASE
        WHEN employee_id IS NULL THEN 'UNRESOLVED'
        WHEN match_count > 1 THEN 'DUPLICATE'
        WHEN person_id IS NULL THEN 'NO_PERSON'
        ELSE 'READY'
    END AS match_status
FROM employee_matches;

-- Review this result before using the staged payload.
SELECT
    employee_id,
    user_id,
    person_id,
    first_name,
    last_name,
    is_approver,
    match_status
FROM #person_approver_updates
ORDER BY last_name, first_name, employee_id;

-- The following update is intentionally disabled. Execute only after reviewing
-- the result above and obtaining the required approval in your change process.
/*
UPDATE p
SET p.IS_APPROVER = u.is_approver
FROM LIVE.dbo.PERSON AS p
INNER JOIN #person_approver_updates AS u
    ON u.user_id = p.ID
WHERE u.match_status = 'READY'
  AND ISNULL(p.IS_APPROVER, '') <> u.is_approver;
*/