# NCM Database Integration Guide

## Overview

This guide describes the current database integration for the NCM form.

- The app supports two NCM database environments: `sandbox` and `production`.
- Every client request must send the `x-db-env` header.
- API routes read that header with `getDbEnvFromHeader()` and pass the result to `queryDatabase(..., env)`.
- Both environments use the identical **target schema** table names defined in `lib/dbSchemaContract.ts`.
- Some validation and lookup flows also use the separate Visual database through `lib/visualDatabase.ts`.

The authoritative field-by-field mapping lives in `DATABASE_MAPPING.md`. This document focuses on setup, routing, CRUD behavior, and the overall integration model.

---

## Environment Setup

### Install dependencies

```bash
npm install
```

### Main NCM database configuration

The main database layer in `lib/database.ts` maintains separate pools for sandbox and production.

```dotenv
# Sandbox NCM database
DB_SERVER=CRUNCH2018.skillsinc.local
DB_PORT=1433
DB_DATABASE=SANDBOX_NCM

# Production NCM database
PROD_DB_SERVER=SQL-Visual-2.skillsinc.local
PROD_DB_DATABASE=NCM

# Main DB authentication
DB_AUTHENTICATION=windows
DB_DOMAIN=skillsinc.local
DB_USER=
DB_PASSWORD=

# New database SQL login (used automatically when DB_DATABASE or PROD_DB_DATABASE is NCM or SANDBOX_NCM)
NEW_DB_USER=
NEW_DB_PASSWORD=

# Timeouts
DB_CONNECT_TIMEOUT=15000
DB_REQUEST_TIMEOUT=30000

# Defaults for inserted rows
NCM_ENTITY_ID=SK01
NCM_SITE_ID=SK01
```

Notes:

- When `DB_AUTHENTICATION=windows`, the main NCM pools use NTLM auth.
- Otherwise the app falls back to SQL auth using `DB_USER` and `DB_PASSWORD`.
- When either configured database is `NCM` or `SANDBOX_NCM`, the app automatically uses `NEW_DB_USER` and `NEW_DB_PASSWORD` if they are set.
- Sandbox uses `DB_SERVER` and `DB_DATABASE`.
- Production uses `PROD_DB_SERVER` and `PROD_DB_DATABASE`.

### Visual database configuration

Several lookups rely on the Visual database, especially part, work-order, operation, supplier/customer, and employee resolution.

```dotenv
VISUAL_DB_SERVER=
VISUAL_DB_PORT=1433
VISUAL_DB_DATABASE=
VISUAL_DB_USER=
VISUAL_DB_PASSWORD=
VISUAL_DB_ENCRYPT=true
VISUAL_DB_TRUST_SERVER_CERTIFICATE=false
```

Notes:

- `lib/visualDatabase.ts` currently uses SQL auth, not NTLM.
- If Visual DB access is unavailable, `/api/employee/[id]` falls back to `EMPLOYEE_LOOKUP` in the selected NCM environment.

---

## Environment Routing Pattern

Every database-backed feature should follow this pattern:

1. Client code calls `getDbHeaders()` or `useDbHeaders()` from `lib/fetchWithEnv.ts`.
2. The helper injects `{ "x-db-env": "sandbox" | "production" }`.
3. The API route calls `getDbEnvFromHeader(request)` from `lib/dbEnvHeader.ts`.
4. The route passes the resolved environment into `queryDatabase()`.

Default behavior:

- Missing or invalid `x-db-env` header falls back to `sandbox`.
- `lib/database.ts` keeps one pool per environment and retries once on `ECONNCLOSED`.

---

## Form Architecture

### Form modes

`useNCMStore` tracks four modes:

| Mode     | Meaning                    |
| -------- | -------------------------- |
| `new`    | Creating a record          |
| `view`   | Viewing an existing record |
| `edit`   | Editing an existing record |
| `search` | Showing search results     |

### Current form layout

The NCM form is a single scrollable page (tabs were removed) with these sections:

1. Tag Information
2. Job Information
3. Tag Data (MFG/FIN toggle + Process → Sub Process → Defect cascade)
4. Description fields
5. Disposition (visible to all roles; read-only unless Admin or Disposition member)
6. Verification (open to all roles)
7. Corrective Actions

NCM type `Overage` hides the Disposition and Verification sections. Older references to a 7-tab layout are no longer accurate.

### Current client-side required fields

Before save, the form requires:

- Part Number
- Work Order **or** Vendor PO Num (supplier NCM types require Vendor PO Num + Supplier ID)
- Made By Employee ID
- Assigned To Employee ID
- NCM Type
- Lot Size
- "As Is" Dimension and "Should Be" Dimension (non-overage types)
- Closed Date when status is `closed`

The API itself is less strict for create, but the UI blocks save until those fields are populated.

---

## API Routes

### `GET /api/ncm/[ncm-id]`

Loads a single NCM record by `NCM_NUMBER` with joined display data. Target-schema columns are aliased back to the legacy payload keys the form expects (see `DATABASE_MAPPING.md`).

Joined data includes:

- Disposition type description (`DISPOSITION_TYPE` join)
- Employee badge IDs and display names (five `EMPLOYEE_LOOKUP` joins: made by, assigned to, disposition by, disposition assigned to, verified by)

### `POST /api/ncm/new`

Creates a new record. This is handled by `app/api/ncm/[id]/route.ts` with `id = "new"`.

Current create behavior:

- `NCM_DATE` is required by the API.
- `NCM_ID` is optional.
- If `NCM_ID` is blank, the database generates the final NCM number.
- If a non-blank `NCM_ID` already exists, the API returns `409`.

### `POST /api/ncm/search`

Searches `NONCONFORMANCE` by `NCM_NUMBER LIKE @search_term` and returns up to 20 rows ordered by `NCM_DATE` descending.

Response fields (aliased to legacy names):

- `RECORD_ID` (from `NONCONFORMANCE_ID`)
- `NCM_ID` (from `NCM_NUMBER`)
- `NCM_DATE`
- `STATUS` (from `NCM_STATUS`)
- `DESCRIPTION` (from `NCM_DESCRIPTION`)

### `PUT /api/ncm/[ncm-id]`

Updates an existing NCM record.

Current update behavior:

- The payload still uses legacy keys (`MADE_BY_EMP_REC_ID`, `USER_DEFINED_1`, `SK_AS_IS`, ...); the route translates them to target-schema columns through `targetFieldMap` (see the alias table in `DATABASE_MAPPING.md`).
- Employee fields accept either a badge ID (`EMPLOYEE_ID`) or an internal `RECORD_ID` and are normalized to the badge ID before saving into `*_EMPLOYEE_ID` columns.
- `REPORTED_BY_SUPP_REC_ID` is resolved through the supplier lookup before saving into `REPORTED_BY_SUPPLIER_ID`.
- `PROD_ORDER_REC_ID` is parsed into `BASE_ID` / `LOT_ID` / `SPLIT_ID` / `SUB_ID`.
- Only allowlisted fields are updated; every update also sets `UpdatedAt = SYSUTCDATETIME()`.

Normalized employee fields:

- `MADE_BY_EMP_REC_ID` → `MADE_BY_EMPLOYEE_ID`
- `ASSIGNED_TO_REC_ID` → `ASSIGNED_TO_EMPLOYEE_ID`
- `DISP_EMP_REC_ID` → `DISPOSITION_BY_EMPLOYEE_ID`
- `DISP_ASSG_TO_REC_ID` → `DISPOSITION_ASSIGNED_TO_EMPLOYEE_ID`
- `VERIFY_BY_REC_ID` → `VERIFIED_BY_EMPLOYEE_ID`

### `DELETE /api/ncm/[ncm-id]`

Deletes the NCM row. Admins only (enforced in the UI).

---

## Lookup and Validation Endpoints

### `GET /api/ncm/lookups`

Returns lookup sets used by the form:

- NCM types (`NCM_TYPE`)
- Disposition types (`DISPOSITION_TYPE`)
- Processes (`PROCESS`)
- Subprocesses (`SUBPROCESS`)
- Defects (`DEFECT`)

The Process → Sub Process → Defect cascade is filtered client-side by business unit (`MFG` / `FIN` / `BOTH`).

### `GET|POST|DELETE /api/ncm/defect-photo`

Manages defect sample photos in the `DEFECT_PHOTO` table, keyed by defect **name** (one photo covers the defect under every process/subprocess).

Current behavior:

- `GET` is open to all roles; `POST` and `DELETE` are admin-only.
- Photos are stored as binary with a MIME type and returned as a browser-displayable data URL.
- Rejects uploads larger than 5 MB and non-image uploads.

### `GET /api/ncm/field-lookup`

Used by the form to validate and resolve IDs. All lookups query the Visual `LIVE` database.

Supported `field` values:

- `partNumber` — validates against `LIVE.dbo.PART`
- `workOrderId` — parses `BASE/LOT/SPLIT/SUB` and validates against `LIVE.dbo.WORK_ORDER`
- `operationId` — uses the selected work order and `LIVE.dbo.OPERATION` to derive `RESOURCE_ID`
- `supplierId` — validates against `LIVE.dbo.VENDOR`
- `customerId` — validates against `LIVE.dbo.CUSTOMER`

### `GET /api/employee/[id]`

Returns employee name data for a badge ID or record ID.

Current response shape:

```json
{
  "FIRST_NAME": "John",
  "LAST_NAME": "Doe"
}
```

Behavior:

- Tries Visual `LiveSupplemental.dbo.ADP_EMP` first.
- Falls back to `EMPLOYEE_LOOKUP` in the selected NCM environment.

### `GET /api/ncm/disposition-lookups/search`

Party picker search endpoint for Disposition By:

- `type=customer` searches Visual `LIVE.dbo.CUSTOMER`
- `type=supplier` searches Visual `LIVE.dbo.VENDOR`

Returns up to 50 rows matching ID or name (minimum 2-character query).

---

## Database Utilities

### `lib/database.ts`

Provides:

- `getConnection(env)`
- `closeConnection(env?)`
- `queryDatabase<T>(query, params, env)`
- `executeStoredProcedure<T>(procedureName, params, env)`

Current characteristics:

- Separate pools for sandbox and production
- Shared timeout config
- Retry on `ECONNCLOSED`
- Parameter binding for all queries in this layer

### `lib/visualDatabase.ts`

Provides:

- `getVisualConnection()`
- `queryVisualDatabase<T>(query, params)`

Used for:

- Part number validation
- Work-order and operation/resource validation
- Supplier and customer validation/search
- Employee name resolution (`ADP_EMP`)

### `lib/dbSchemaContract.ts`

Defines the target-schema table names (`TARGET_DB_OBJECTS` / `TARGET_LOOKUP_OBJECTS`). `getDbObjects(env)` and `getLookupObjects(env)` always return the target names — sandbox is a full structural copy of production so it can be promoted directly on cutover day.

---

## Field Mapping Status

Do not rely on older summary lists of “linked” and “not linked” fields in this file. Use `DATABASE_MAPPING.md` as the authoritative map for:

- load aliases returned by `GET /api/ncm/[id]`
- persisted columns written by `PUT /api/ncm/[id]` (the `targetFieldMap` alias table)
- natural-ID storage (part number in `PART_ID`, badge IDs in `*_EMPLOYEE_ID`, work order in `BASE_ID`/`LOT_ID`/`SPLIT_ID`/`SUB_ID`)
- derived display-only fields such as employee names and descriptions

---

## Email Integration

### `POST /api/send-email`

Sends NCM notification email via SMTP and, when `ncmId` is supplied, updates `IS_SUPPLIER_NOTICE_SENT = 1` in the selected NCM environment. Every send is also recorded in the `EMAIL_LOG` table (viewable per NCM through `/api/ncm/[id]/email-log`).

Current request body:

```json
{
  "to": "recipient@company.com",
  "cc": "copy@company.com",
  "subject": "NCM Notification",
  "text": "Message body",
  "ncmId": "NCM-2026-001",
  "attachmentIds": ["document-rowpointer-guid"]
}
```

Current response shape:

```json
{
  "success": true,
  "noticeSentUpdated": true,
  "attachmentsSent": 1
}
```

Email templates are managed in `SK_EMAIL_TEMPLATES` via the admin endpoint `/api/ncm/admin/email-templates`. Setting `EMAIL_PLANNING_FOR_REWORK = 1` on an NCM triggers a one-time rework notification to planning; `EMAIL_PLANNING_SENT_AT` records when it was sent.

---

## Common Errors

| Error                                          | Meaning                                                       |
| ---------------------------------------------- | ------------------------------------------------------------- |
| `Search term is required`                      | `/api/ncm/search` was called without a search term            |
| `NCM_DATE is required`                         | Create request omitted the required date                      |
| `NCM ID already exists`                        | A user-supplied NCM ID conflicts with an existing row (`409`) |
| `Invalid employee for ...`                     | An employee field could not be resolved to a badge ID         |
| `Invalid supplier for Reported By Supplier ID` | The supplier ID could not be resolved through the lookup      |

---

## Troubleshooting

### Main DB connection problems

- Verify sandbox and production hostnames independently.
- Confirm the chosen auth mode matches the environment.
- If using NTLM, check `DB_DOMAIN`, `DB_USER`, and `DB_PASSWORD`.
- Increase `DB_CONNECT_TIMEOUT` or `DB_REQUEST_TIMEOUT` if the server is slow.

### Visual DB lookup failures

- Check `VISUAL_DB_*` variables.
- If part or operation validation fails while NCM DB reads still work, the issue is usually in the Visual DB connection.
- Employee lookup can still succeed through the `EMPLOYEE_LOOKUP` fallback even when Visual DB is unavailable.

### Query shape mismatches

- Verify the save payload still matches the allowlist and `targetFieldMap` in `app/api/ncm/[id]/route.ts`.
- Verify the load mapping in `components/NCMForm.tsx` still matches the aliases returned by `GET /api/ncm/[id]`.

---

## Security Notes

1. Environment selection is explicit per request via `x-db-env`.
2. Query parameters are bound through the database helpers.
3. The update route enforces an allowlist before building dynamic SQL.
4. Destructive actions still require explicit UI action, but role restrictions are frontend-driven.

---

## References

- `lib/database.ts`
- `lib/visualDatabase.ts`
- `lib/dbSchemaContract.ts`
- `lib/dbEnvHeader.ts`
- `lib/fetchWithEnv.ts`
- `app/api/ncm/[id]/route.ts`
- `app/api/ncm/search/route.ts`
- `app/api/ncm/lookups/route.ts`
- `app/api/ncm/field-lookup/route.ts`
- `app/api/ncm/defect-photo/route.ts`
- `app/api/employee/[id]/route.ts`
- `app/api/send-email/route.ts`
