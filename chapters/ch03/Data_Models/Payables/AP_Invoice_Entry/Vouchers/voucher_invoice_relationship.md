# Voucher ↔ Invoice Relationship (mapping)

This note summarizes how invoices, vouchers, distributions, and payments relate in Visual/Live, and documents an important distinction for the `AP_App` data models (external/upload systems).

**Source DDL (authoritative)**
- `Documentation/Data Models/ddl/schema-extract/output/LIVE/dbo.PAYABLE.sql`
- `Documentation/Data Models/ddl/schema-extract/output/LIVE/dbo.PAYABLE_LINE.sql`
- `Documentation/Data Models/ddl/schema-extract/output/LIVE/dbo.CASH_DISBURSE_LINE.sql`

**High-level mapping**
- Invoice number (supplier-supplied): `PAYABLE.INVOICE_ID`.
- System voucher id (primary identifier used across AP): `PAYABLE.VOUCHER_ID` (primary key on `PAYABLE`).
- Distributions / invoice lines: `PAYABLE_LINE` rows point to `PAYABLE` via `VOUCHER_ID`.
- Payments / remittances: `CASH_DISBURSE_LINE.VOUCHER_ID` references `PAYABLE.VOUCHER_ID` and link to `CASH_DISBURSEMENT` by (`BANK_ACCOUNT_ID`, `CONTROL_NO`).
- Vendor link: `PAYABLE.VENDOR_ID` → `VENDOR.ID`.

**Typical workflow (concise)**
1. Goods receipt (if PO-based) created in purchasing/receiving.
2. AP Invoice entry (matched or non-PO) creates a `PAYABLE` header and `PAYABLE_LINE` distribution rows.
   - The invoice's supplier number is stored in `PAYABLE.INVOICE_ID`.
   - The system `VOUCHER_ID` is generated and used as the PK for later linking.
3. When payment is made, `CASH_DISBURSEMENT` (header) and `CASH_DISBURSE_LINE` rows are created; lines reference `PAYABLE` through `VOUCHER_ID` to apply payments.

**Practical example joins**
- Invoice header with distributions (filter by posting date):

```sql
SELECT P.VOUCHER_ID, P.INVOICE_ID, P.POSTING_DATE, P.TOTAL_AMOUNT,
       PL.LINE_NO, PL.AMOUNT, PL.GL_ACCOUNT_ID
FROM Live.dbo.PAYABLE P
LEFT JOIN Live.dbo.PAYABLE_LINE PL ON PL.VOUCHER_ID = P.VOUCHER_ID
WHERE P.POSTING_DATE BETWEEN @StartDate AND @EndDate;
```

- Payments applied to a voucher:

```sql
SELECT P.VOUCHER_ID, P.INVOICE_ID, P.TOTAL_AMOUNT, CDL.AMOUNT AS PaidAmount,
       CD.CHECK_DATE, CDL.REFERENCE_INFO
FROM Live.dbo.PAYABLE P
LEFT JOIN Live.dbo.CASH_DISBURSE_LINE CDL ON CDL.VOUCHER_ID = P.VOUCHER_ID
LEFT JOIN Live.dbo.CASH_DISBURSEMENT CD
  ON CD.BANK_ACCOUNT_ID = CDL.BANK_ACCOUNT_ID AND CD.CONTROL_NO = CDL.CONTROL_NO
WHERE P.VOUCHER_ID = @VoucherId;
```

**Important note about `AP_App` and external imports**
- Several files in `Documentation/Data Models/AP_App/` and the `AP Automation` reports reference a separate ingestion schema (examples in these files show `APV.ID`, `APV.VOUCHER_NO`, or `tblFiles.[Voucher#]`). The `AP_App` source is a different database (`dbRMS`) and different schema from the `Live`/Visual database used for the authoritative DDL above.
- Example header comment found in `AP_App.sql`:

```
-- file path: SQL_Reports/Visual Enterprise Financial Reports/AP App Invoices without Vouchers.sql
-- data models: AP_App
-- fike path: SQL_Data_Models/AP_App/AP App Invoices.sql
-- note AP Automation is a different perspective, and a different schema.
-- It's a dfferent DB as well: dbRMS vs Live, on sql-lab-1.
```

Do not assume `AP_App` column names always match the `Live` schema; where possible, join/compare by the system voucher identifier (after casting or normalization) rather than by supplier invoice number, or validate column names against the authoritative DDL before replacing references.

**Common pitfalls / repo findings**
- `INVOICE_NO` appears in some reports and older queries — authoritative schema uses `INVOICE_ID`. Review each occurrence before bulk replacing.
- Some custom reports map `P.VOUCHER_ID = R.INVOICE_ID` for specific integrations (TMX); treat these as exceptions.

**Next actions (suggested)**
- Keep `AP_App` notes in-place to remind readers that dbRMS vs Live are separate systems.
- Optionally run a repo search for `INVOICE_NO` and produce a suggested patch list (safe-mode — only propose changes).

_Created: automated summary to assist reviewers and report authors — update if you find system-specific exceptions._
