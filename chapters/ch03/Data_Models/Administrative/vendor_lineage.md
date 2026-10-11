# VENDOR — Lineage Document

| Field | Value |
|---|---|
| ERP Table | `dbo.VENDOR` |
| DDL Source | `Utilities\SQLMesh\ddl\dbo.VENDOR.sql` |
| Schema Catalog | `schema_catalog.db` → 119 columns |
| Masking Certificate | `RECV-2026-04-01-003` v1.5 (certified) |
| Receiver ID | `RECR-2026-04-01-003` |
| DAG Entry | 1.1 — `vendor.id` — `hash_sha256(id,length)` |
| Masking Mode | **Exploit** — cert + salt verified; `id` not hashed |
| Raw Model | `Utilities\SQLMesh\models\raw\raw_vendor.py` |
| Staging Model | `Utilities\SQLMesh\models\staging\rcvr_vendor.sql` |
| SQLite Schema | `erp_vendor` in `hf-space-inventory-sqlgen\app_schema\schema_sqlite.sql` |
| Row Count (confirmed) | 756 rows (sql-lab-2 / Staging.dbo.VENDOR) |

## Staged Columns (18 ERP + 4 cert)

| Column | SQL Server Type | SQLite Type | Notes |
|---|---|---|---|
| ROWID | int | INTEGER | |
| ID | NVARCHAR(15) | TEXT | **PK** · DAG 1.1 key |
| NAME | NVARCHAR(50) | TEXT | |
| ADDR_1 | NVARCHAR(50) | TEXT | |
| ADDR_2 | NVARCHAR(50) | TEXT | |
| CITY | NVARCHAR(30) | TEXT | |
| STATE | NVARCHAR(10) | TEXT | |
| ZIPCODE | NVARCHAR(10) | TEXT | |
| COUNTRY | NVARCHAR(50) | TEXT | |
| CONTACT_FIRST_NAME | NVARCHAR(30) | TEXT | |
| CONTACT_LAST_NAME | NVARCHAR(30) | TEXT | |
| CONTACT_PHONE | NVARCHAR(20) | TEXT | |
| CONTACT_EMAIL | NVARCHAR(100) | TEXT | |
| BUYER | NVARCHAR(20) | TEXT | |
| TERMS_NET_DAYS | smallint | INTEGER | |
| TERMS_DISC_PERCENT | DECIMAL(5,3) | REAL | |
| ACTIVE_FLAG | NCHAR(1) | TEXT | Staging-specific; not in LIVE DDL |
| OPEN_DATE | datetime | TEXT | |
| MODIFY_DATE | datetime | TEXT | |
| receiving_id | — | TEXT | Cert metadata |
| receiver_id | — | TEXT | Cert metadata |
| cert_status | — | TEXT | Cert metadata |
| cert_version | — | TEXT | Cert metadata |

> **Note:** 101 of 119 DDL columns are not yet staged. These exist in the certified
> DDL (`erp_vendor` in `schema_sqlite.sql`) and will be staged in future iterations.

## Parent Chain

None — VENDOR is the root DAG node (DAG 1.1).

## Children

| Table | DAG | Relationship |
|---|---|---|
| PART | 1.2 | `PART.PREF_VENDOR_ID` → `VENDOR.ID` |

## Certification History

| Certificate | Date | Version | Status |
|---|---|---|---|
| RECV-2026-04-01-003 | 2026-04-01 | 1.5 | certified |
