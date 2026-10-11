# Working with Invoice Entry Tables

This page describes common table names and configuration points used by A/P Invoice Entry and tips for reporting.

Common objects:

- `AP_VOUCHER` / `AP_INVOICE` — voucher/header information (Voucher ID, Vendor ID, Voucher Date, Total, Posted flag).
- `AP_VOUCHER_LINE` / `AP_INVOICE_LINE` — voucher line items (item/service code, quantity, amount, GL distribution).
- `AP_PAYMENTS` — payment records linked to vouchers.

Configuration tips:

- Adjust the Invoice Entry line-item table columns to include distribution columns you need (GL account, cost center, job number, tax code).
- Configure default GL accounts for item types to reduce manual errors.

Reporting:

- Join header and line tables on `Voucher ID` or `Invoice ID` and use `Vendor ID` to filter vendor-specific reports.
- Export large datasets to CSV or a reporting database for heavy analytical queries instead of querying OLTP tables directly.

Index: `../../Accounts_Payable_INDEX.md`
